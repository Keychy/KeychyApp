//
//  KeyringScene.swift
//  KeytschPrototype
//
//  Created by Jini on 10/16/25.
//

import SwiftUI
import SpriteKit
import Combine
import Lottie

class KeyringScene: SKScene {
    // MARK: - SwiftUI로 콜백 전달용
    var onPlayParticleEffect: ((String) -> Void)?
    var onSetupComplete: (() -> Void)?  // Setup 완료 콜백

    // MARK: - Properties
    var bodyImage: UIImage? // UIImage용
    var bodyImageURL: String? // Firebase URL용
    var templateId: String // 템플릿 ID (KeyringScale용)
    var isGyroscope: Bool // 자이로 인터랙션 사용 여부
    var screen: KeyringScale.Screen // 화면 종류 (zoomScale용)
    var customSoundURL: URL? // 커스텀 녹음 파일 URL
    var hookOffsetY: CGFloat? // 바디 연결 지점 Y 오프셋 (nil이면 0.0 사용)
    var chainLength: Int = 5 // 체인 링크 개수 (기본값 5)
    var previewScale: CGFloat = 1.0 // 기기별 프리뷰 스케일 (카메라 줌에 반영)
    var hasDynamicIsland: Bool = true // DI 기기 여부 (링 위치 분기용)
    var cancellables = Set<AnyCancellable>()
    var currentSoundId: String = "none"
    var currentParticleId: String = "none"

    // MARK: - 선택된 타입들
    var currentRingType: RingType = .basic
    var currentChainType: ChainType = .basic
    var currentBodyType: BodyType = .basic

    // MARK: - 구성 요소들
    var ringNode: SKSpriteNode?
    var chainNodes: [SKSpriteNode] = []
    var bodyNode: SKNode?

    // MARK: - 스와이프 제스처 관련
    var lastTouchLocation: CGPoint?
    var lastTouchTime: TimeInterval = 0
    var swipeStartLocation: CGPoint?

    // MARK: - 이펙트 쓰로틀링
    /// 쓰로틀링(Throttling)은 일정 시간 간격으로 실행 횟수를 제한하는 기법. 이라고 합니다.
    /// 마지막 실행 시간을 기록해두고, 일정 시간이 지나야만 다시 실행할 수 있게!
    /// 과도한 함수 호출을 방지합니다.
    /// ---> 흔들기를 과도하게 했을때, 파티클이 중앙에서 안퍼지고 모여있는게 매우 부자연스러워보여서 추가함.
    var lastParticleTime: TimeInterval = 0

    // MARK: - 씬 정리 상태
    var isCleaningUp = false

    // MARK: - 렌티큘러 햅틱
    private var lenticularHaptic: LenticularHapticManager?

    // MARK: - 배경색 설정
    var customBackgroundColor: UIColor = .gray50

    // MARK: - Init / Deinit
    init(
        ringType: RingType,
        chainType: ChainType,
        templateId: String,
        isGyroscope: Bool = false,
        screen: KeyringScale.Screen = .customizing,
        bodyImage: UIImage? = nil,
        bodyImageURL: String? = nil,
        backgroundColor: UIColor = .gray50,
        hookOffsetY: CGFloat? = nil,
        chainLength: Int = 5,
        previewScale: CGFloat = 1.0,
        hasDynamicIsland: Bool = true
    ) {
        self.currentRingType = ringType
        self.currentChainType = chainType
        self.templateId = templateId
        self.isGyroscope = isGyroscope
        self.screen = screen
        self.bodyImageURL = bodyImageURL
        self.customBackgroundColor = backgroundColor
        self.hookOffsetY = hookOffsetY
        self.chainLength = chainLength
        self.previewScale = previewScale
        self.hasDynamicIsland = hasDynamicIsland

        if let image = bodyImage {
            self.bodyImage = image.fixedOrientation()
        } else {
            self.bodyImage = nil
        }
        super.init(size: .zero)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    deinit {
        cleanup()
    }

    /// 씬 정리 (메모리 해제 전 호출)
    func cleanup() {
        guard !isCleaningUp else { return }
        isCleaningUp = true

        // 자이로 정지
        if isGyroscope {
            LenticularMotionManager.shared.stop()
            lenticularHaptic = nil
        }

        // 콜백 무효화
        onPlayParticleEffect = nil
        onSetupComplete = nil

        // Combine 구독 취소
        cancellables.removeAll()

        // 모든 물리 조인트 제거
        physicsWorld.removeAllJoints()

        // 모든 액션 제거
        removeAllActions()

        // 모든 자식 노드 제거
        removeAllChildren()

        // 노드 참조 제거
        ringNode = nil
        chainNodes.removeAll()
        bodyNode = nil
    }
    
    // MARK: - ViewModel 바인딩 (Generic)
    func bind<VM: KeyringViewModelProtocol>(to viewModel: VM) {
        // 커스텀 사운드 URL 전달
        self.customSoundURL = viewModel.customSoundURL

        // 초기값 설정 (effectSubject 이벤트 없이도 currentSoundId/currentParticleId 설정)
        self.currentSoundId = viewModel.soundId
        self.currentParticleId = viewModel.particleId

        viewModel.effectSubject
            .sink { [weak self] (soundId, particleId, type) in
                guard let self = self else { return }
                self.currentSoundId = soundId
                self.currentParticleId = particleId

                // 커스텀 사운드 URL 업데이트 (effectSubject가 발생할 때마다)
                self.customSoundURL = viewModel.customSoundURL

                switch type {
                case .sound:
                    self.applySoundEffect(soundId: soundId)
                case .particle:
                    self.applyParticleEffect(particleId: particleId)
                }
            }
            .store(in: &cancellables)

        // 렌티큘러 등 자이로 템플릿: 초기 스타일(시머/테두리) 적용
        // - 편집 중(LenticularVM): selectedShimmerEffect.firestoreId 반환
        // - 영상 생성 시(KeyringAdapter): 저장된 Keyring 모델의 ID 반환
        // 어느 경로든 `KeyringAppearanceColor.from(id:)`로 nil-safe 복원 가능
        if viewModel.isGyroscope {
            let initialShimmer = KeyringAppearanceColor.from(id: viewModel.shimmerColorId)
            let initialBorder = KeyringAppearanceColor.from(id: viewModel.borderColorId)
            let originalSetupComplete = self.onSetupComplete
            self.onSetupComplete = { [weak self] in
                self?.updateStyleUniforms(shimmer: initialShimmer, border: initialBorder)
                originalSetupComplete?()
            }
        }

        // LenticularVM 전용: styleSubject 구독 → 편집 중 시머/테두리 실시간 업데이트
        if let lenticularVM = viewModel as? LenticularVM {
            lenticularVM.styleSubject
                .sink { [weak self] update in
                    self?.updateStyleUniforms(shimmer: update.shimmer, border: update.border)
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - 스타일 셰이더 Uniform 실시간 업데이트
    /// bodyNode 내부의 lenticularVisual 셰이더에 시머/테두리 색상 독립 적용
    func updateStyleUniforms(shimmer: KeyringAppearanceColor, border: KeyringAppearanceColor) {
        guard let body = bodyNode,
              let transform = body.childNode(withName: "lenticularTransform") as? SKTransformNode,
              let visual = transform.childNode(withName: "lenticularVisual") as? SKSpriteNode,
              let shader = visual.shader else { return }

        let sc = shimmer.shaderColor
        shader.uniformNamed("u_shimmer_color")?.vectorFloat3Value = vector_float3(sc.r, sc.g, sc.b)
        shader.uniformNamed("u_shimmer_mode")?.floatValue = shimmer.shaderMode

        let bc = border.shaderColor
        shader.uniformNamed("u_border_color")?.vectorFloat3Value = vector_float3(bc.r, bc.g, bc.b)
        shader.uniformNamed("u_border_mode")?.floatValue = border.shaderMode
    }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = customBackgroundColor
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        // 카메라 설정 (zoomScale 적용)
        setupCamera()

        setupKeyring()

        // 자이로 시작 + 햅틱 매니저 생성
        if isGyroscope {
            LenticularMotionManager.shared.start()
            lenticularHaptic = LenticularHapticManager()
        }
    }

    // MARK: - 매 프레임 업데이트
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        // 자이로: SKTransformNode로 바디만 Y축 3D 회전 + 셰이더 u_tilt 갱신 + 햅틱
        if isGyroscope {
            let tilt = LenticularMotionManager.shared.tilt
            let signedTilt = LenticularMotionManager.shared.signedTilt
            let signedPitch = LenticularMotionManager.shared.signedPitch

            if let body = bodyNode,
               let transform = body.childNode(withName: "lenticularTransform") as? SKTransformNode {
                // 바디만 3D 회전 (고리/체인은 영향 없음)
                transform.yRotation = CGFloat(signedTilt) * KeyringScale.lenticularYRotationMax
                transform.xRotation = CGFloat(signedPitch) * KeyringScale.lenticularXRotationMax

                // 셰이더 업데이트 (렌티큘러 A↔B 전환)
                if let visual = transform.childNode(withName: "lenticularVisual") as? SKSpriteNode,
                   let shader = visual.shader {
                    shader.uniformNamed("u_tilt")?.floatValue = Float(tilt)
                }
            }
            // 햅틱은 transform 존재 여부와 무관하게 항상 동작
            lenticularHaptic?.update(tilt: tilt)
        }
    }

    /// 카메라 설정 - zoomScale 적용
    private func setupCamera() {
        let cameraNode = SKCameraNode()
        let zoom = KeyringScale.zoomScale(for: screen, template: templateId)

        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)

        // zoomScale + previewScale 적용 (카메라 scale은 역수)
        cameraNode.setScale(1.0 / (zoom * previewScale))

        addChild(cameraNode)
        self.camera = cameraNode
    }
}
