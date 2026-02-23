//
//  MultiKeyringSceneView.swift
//  Keychy
//
//  Created by rundo on 11/05/25.
//

import SwiftUI
import SpriteKit
import Lottie

/// 파티클 효과 데이터 모델
struct ParticleEffect: Identifiable {
    let id = UUID()
    let keyringIndex: Int       // 키링 인덱스
    let effectName: String       // 로티 애니메이션 이름
    let position: CGPoint        // SwiftUI 좌표계 위치
}

/// 여러 키링을 하나의 씬에 표시하는 SwiftUI View
struct MultiKeyringSceneView: View {
    let keyringDataList: [MultiKeyringScene.KeyringData]
    let ringType: RingType
    let chainType: ChainType
    let backgroundColor: UIColor
    let backgroundImageURL: String?
    let backgroundLottieId: String?
    let carabinerBackImageURL: String?
    let carabinerFrontImageURL: String?
    let carabinerLottieId: String?
    let carabinerId: String
    let carabinerX: CGFloat
    let carabinerY: CGFloat
    let carabinerWidth: CGFloat
    let currentCarabinerType: CarabinerType
    let cleanupOnDisappear: Bool
    let onBackgroundLoaded: (() -> Void)?
    let onAllKeyringsReady: (() -> Void)?

    @State private var scene: MultiKeyringScene?
    @State private var particleEffects: [ParticleEffect] = []
    @State private var backgroundImage: UIImage?
    @State private var carabinerLottieAspectRatio: CGFloat = 1.0

    // 기본 화면 크기 (iPhone 16 Pro 기준)
    private let defaultSceneSize = CGSize(width: 402, height: 874)

    init(
        keyringDataList: [MultiKeyringScene.KeyringData],
        ringType: RingType = .basic,
        chainType: ChainType = .basic,
        backgroundColor: UIColor = .clear,
        backgroundImageURL: String? = nil,
        backgroundLottieId: String? = nil,
        carabinerBackImageURL: String? = nil,
        carabinerFrontImageURL: String? = nil,
        carabinerLottieId: String? = nil,
        carabinerId: String = "",
        carabinerX: CGFloat = 0,
        carabinerY: CGFloat = 0,
        carabinerWidth: CGFloat = 0,
        currentCarabinerType: CarabinerType,
        cleanupOnDisappear: Bool = false,
        onBackgroundLoaded: (() -> Void)? = nil,
        onAllKeyringsReady: (() -> Void)? = nil
    ) {
        self.keyringDataList = keyringDataList
        self.ringType = ringType
        self.chainType = chainType
        self.backgroundColor = backgroundColor
        self.backgroundImageURL = backgroundImageURL
        self.backgroundLottieId = backgroundLottieId
        self.carabinerBackImageURL = carabinerBackImageURL
        self.carabinerFrontImageURL = carabinerFrontImageURL
        self.carabinerLottieId = carabinerLottieId
        self.carabinerId = carabinerId
        self.carabinerX = carabinerX
        self.carabinerY = carabinerY
        self.carabinerWidth = carabinerWidth
        self.currentCarabinerType = currentCarabinerType
        self.cleanupOnDisappear = cleanupOnDisappear
        self.onBackgroundLoaded = onBackgroundLoaded
        self.onAllKeyringsReady = onAllKeyringsReady
    }

    var body: some View {
        ZStack {
            backgroundView
            carabinerBackLottieOverlay   // 카라비너 뒷면 Lottie (SpriteKit 씬 뒤)
            sceneView
            carabinerFrontLottieOverlay  // 카라비너 앞면 Lottie (hamburger만, 씬 앞)
            particleEffectsView
        }
        .onAppear {
            if scene == nil {
                loadBackgroundImage()
                loadCarabinerLottieAspectRatio()
                setupScene()
            } else {
                // 탭 전환 복귀 시: onDisappear에서 nil 처리된 콜백 복원
                restoreCallbacksIfNeeded()
            }
        }
        .onChange(of: backgroundImageURL) { _, _ in
            loadBackgroundImage()
        }
        .onChange(of: currentCarabinerType) { _, _ in
            loadCarabinerLottieAspectRatio()
            setupScene()
        }
        .onDisappear {
            // .id() 변경으로 뷰가 교체될 때 이전 씬의 비동기 콜백 무효화
            // (비로티 카라비너 이미지 로드가 뒤늦게 완료되어 콜백이 누출되는 것 방지)
            scene?.onSetupComplete = nil

            if cleanupOnDisappear {
                cleanupScene()
            }
        }
    }
}

extension MultiKeyringSceneView {
    /// 배경 뷰 (먼저 렌더링)
    private var backgroundView: some View {
        GeometryReader { geometry in
            Group {
                if let bgLottieId = backgroundLottieId {
                    // Lottie 배경
                    LottieItemView(
                        assetId: bgLottieId,
                        directory: "lottie_backgrounds"
                    )
                    .id(bgLottieId)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else if let backgroundImage {
                    // 정적 이미지 배경 (기존)
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color(backgroundColor)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }

    /// SpriteKit 씬 뷰
    private var sceneView: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            } else {
                Text("뭉치가 하나도 없어요!")
            }
        }
    }

    /// 파티클 효과 레이어
    private var particleEffectsView: some View {
        ForEach(particleEffects) { effect in
            LottieView(
                name: effect.effectName,
                loopMode: .playOnce,
                speed: 1.0
            )
            .allowsHitTesting(false)
            .frame(width: 300, height: 300)
            .position(effect.position)
            .transition(.opacity)
        }
    }

    // MARK: - 카라비너 Lottie 오버레이 (실시간 모드 전용)

    /// 카라비너 뒷면 Lottie 오버레이 (plain + hamburger 공통)
    private var carabinerBackLottieOverlay: some View {
        Group {
            if let lottieId = carabinerLottieId {
                GeometryReader { geometry in
                    let metrics = carabinerScreenMetrics(
                        geometry: geometry, aspectRatio: carabinerLottieAspectRatio
                    )
                    LottieItemView(
                        assetId: lottieId,
                        directory: "lottie_carabiners_back"
                    )
                    .frame(width: metrics.width, height: metrics.height)
                    .position(x: metrics.centerX, y: metrics.centerY)
                    .shadow(color: .black.opacity(0.25), radius: 1.0, x: 2, y: 3)
                }
                .allowsHitTesting(false)
            }
        }
    }

    /// 카라비너 앞면 Lottie 오버레이 (hamburger 타입만)
    private var carabinerFrontLottieOverlay: some View {
        Group {
            if let lottieId = carabinerLottieId,
               currentCarabinerType == .hamburger {
                GeometryReader { geometry in
                    let metrics = carabinerScreenMetrics(
                        geometry: geometry, aspectRatio: carabinerLottieAspectRatio
                    )
                    LottieItemView(
                        assetId: lottieId,
                        directory: "lottie_carabiners_front"
                    )
                    .frame(width: metrics.width, height: metrics.height)
                    .position(x: metrics.centerX, y: metrics.centerY)
                }
                .allowsHitTesting(false)
            }
        }
    }

    /// 씬 좌표(402×874) → 화면 좌표 변환 (aspectFill 스케일링 고려)
    private func carabinerScreenMetrics(
        geometry: GeometryProxy, aspectRatio: CGFloat
    ) -> (width: CGFloat, height: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        let sceneW = defaultSceneSize.width
        let sceneH = defaultSceneSize.height
        // aspectFill: 화면을 꽉 채우도록 스케일 (초과분은 클리핑)
        let scale = max(geometry.size.width / sceneW, geometry.size.height / sceneH)
        let dx = (geometry.size.width - sceneW * scale) / 2
        let dy = (geometry.size.height - sceneH * scale) / 2

        let cbWidth = carabinerWidth * scale
        let cbHeight = carabinerWidth * aspectRatio * scale
        let cbCenterX = dx + (carabinerX + carabinerWidth / 2) * scale
        let cbCenterY = dy + (carabinerY + carabinerWidth * aspectRatio / 2) * scale

        return (cbWidth, cbHeight, cbCenterX, cbCenterY)
    }

    /// 캐시된 Lottie JSON에서 종횡비만 파싱 (렌더링 없음, 즉시 완료)
    private func loadCarabinerLottieAspectRatio() {
        guard let lottieId = carabinerLottieId else { return }
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let path = cacheDir.appendingPathComponent("lottie_carabiners_back/\(lottieId).json")
        if let animation = LottieAnimation.filepath(path.path) {
            carabinerLottieAspectRatio = animation.size.height / animation.size.width
        }
    }

    /// 배경 이미지 로드
    private func loadBackgroundImage() {
        guard let backgroundURL = backgroundImageURL else {
            backgroundImage = nil
            return
        }

        Task {
            if let image = try? await StorageManager.shared.getImage(path: backgroundURL) {
                await MainActor.run {
                    backgroundImage = image
                    // 배경 이미지 로드 완료 콜백 호출
                    onBackgroundLoaded?()
                }
            }
        }
    }

    /// 탭 전환 복귀 시 onDisappear에서 nil 처리된 콜백 복원
    /// onDisappear에서 scene?.onSetupComplete = nil로 설정되므로,
    /// 탭 복귀 시 씬이 아직 로딩 중이면 콜백을 재설정하고
    /// 이미 완료됐으면 즉시 콜백을 호출
    private func restoreCallbacksIfNeeded() {
        guard let scene else { return }

        if scene.isPhysicsEnabled {
            // 씬 로딩이 이미 완료된 상태 → 직접 콜백 호출
            onAllKeyringsReady?()
        } else {
            // 씬이 아직 로딩 중 → 콜백 재설정
            scene.onSetupComplete = {
                onAllKeyringsReady?()
            }
        }
    }

    /// 씬 초기화 및 설정
    private func setupScene() {
        if scene != nil {
            cleanupScene()
        }

        let newScene = MultiKeyringScene(
            keyringDataList: keyringDataList,
            ringType: ringType,
            chainType: chainType,
            backgroundColor: .clear,
            backgroundImageURL: nil,
            carabinerBackImageURL: carabinerBackImageURL,
            carabinerFrontImageURL: carabinerFrontImageURL,
            carabinerId: carabinerId,
            carabinerX: carabinerX,
            carabinerY: carabinerY,
            carabinerWidth: carabinerWidth,
            carabinerLottieId: carabinerLottieId
        )

        newScene.size = defaultSceneSize
        newScene.scaleMode = .aspectFill
        newScene.currentCarabinerType = currentCarabinerType
        newScene.onPlayParticleEffect = handleParticleEffect
        newScene.onSetupComplete = {
            onAllKeyringsReady?()
        }
        scene = newScene
    }

    /// 씬 정리 및 메모리 해제
    private func cleanupScene() {
        // Scene의 cleanup 메서드 호출 (물리 조인트, 예약된 작업 등 정리)
        scene?.cleanup()

        // Scene을 nil로 설정하여 메모리 해제
        scene = nil

        // 배경 이미지도 해제
        backgroundImage = nil

        // 파티클 효과 정리
        particleEffects.removeAll()
    }

    /// 파티클 효과 재생 처리
    private func handleParticleEffect(
        keyringIndex: Int,
        effectName: String,
        spriteKitPosition: CGPoint
    ) {
        let swiftUIPosition = convertToSwiftUIPosition(spriteKitPosition)
        let effect = ParticleEffect(
            keyringIndex: keyringIndex,
            effectName: effectName,
            position: swiftUIPosition
        )

        DispatchQueue.main.async {
            particleEffects.append(effect)
            scheduleEffectRemoval(effect)
        }
    }

    /// SpriteKit 좌표를 SwiftUI 좌표로 변환
    private func convertToSwiftUIPosition(_ spriteKitPosition: CGPoint) -> CGPoint {
        CGPoint(
            x: spriteKitPosition.x,
            y: defaultSceneSize.height - spriteKitPosition.y
        )
    }

    /// 파티클 효과 제거 예약 (2.5초 후)
    private func scheduleEffectRemoval(_ effect: ParticleEffect) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            particleEffects.removeAll { $0.id == effect.id }
        }
    }
}

