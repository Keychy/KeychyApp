//
//  LenticularVM.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class LenticularVM: KeyringViewModelProtocol {
    // MARK: - Template Data
    var template: KeyringTemplate?
    var isLoadingTemplate = false

    // MARK: - Effect Data
    var availableSounds: [Sound] = []
    var availableParticles: [Particle] = []
    var selectedSound: Sound? = nil
    var selectedParticle: Particle? = nil
    var customSoundURL: URL? = nil
    var downloadingItemIds: Set<String> = []
    var downloadProgress: [String: Double] = [:]
    var soundId: String = "none"
    var particleId: String = "none"
    let effectSubject = PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never>()

    // MARK: - Style Data (시머 + 테두리 분리)
    /// 선택된 시머(광택) 효과
    var selectedShimmerEffect: KeyringAppearanceColor = .preset(.silver)
    /// 선택된 테두리 효과
    var selectedBorderEffect: KeyringAppearanceColor = .preset(.silver)

    /// Scene에 스타일 변경을 전달하는 Subject
    struct StyleUpdate {
        let shimmer: KeyringAppearanceColor
        let border: KeyringAppearanceColor
    }
    let styleSubject = PassthroughSubject<StyleUpdate, Never>()

    // MARK: - Lenticular Image Data
    /// 사용자가 선택한 이미지 A (렌티큘러 좌측)
    var imageA: UIImage?
    /// 사용자가 선택한 이미지 B (렌티큘러 우측)
    var imageB: UIImage?

    // MARK: - 이미지 로딩 상태
    var isLoadingImage = false

    // MARK: - Photo Transform State (핀치/드래그 크롭용)
    var photoScaleA: CGFloat = 1.0
    var photoOffsetA: CGSize = .zero
    var photoScaleB: CGFloat = 1.0
    var photoOffsetB: CGSize = .zero

    /// 편집 뷰에서 제스처가 기반으로 하는 카드 크기
    /// `applyScale`/`applyOffset`이 호출될 때 자동 갱신되며,
    /// `composeAtlas`가 targetSize 좌표계로 변환할 때 사용한다.
    var sourceCardSize: CGSize = .zero

    // MARK: - Body Image
    /// A+B 가로 합성 아틀라스 (셰이더가 UV로 좌/우 분리 샘플링)
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0

    // MARK: - Cropped Images (사용자 편집 반영본)
    /// 사용자가 선택/편집한 A/B를 아틀라스용으로 크롭한 결과
    /// FusionView 썸네일 등 편집 결과를 보여줘야 하는 곳에서 사용
    var croppedImageA: UIImage?
    var croppedImageB: UIImage?

    // MARK: - Info Data
    var nameText: String = ""
    var maxTextCount: Int = 10
    var memoText: String = ""
    var maxMemoCount: Int = 500
    var selectedTags: [String] = []
    var createdAt: Date = Date()
    var savedKeyringDocumentId: String?
    var packagedPostOfficeId: String?
    var packagedShareLink: String?

    // MARK: - Dependencies
    var userManager: UserManager
    var errorMessage: String?

    // MARK: - Template Info
    var templateId: String { template?.id ?? "Lenticular" }
    var chainLength: Int { template?.chainLength ?? 3 }
    var isGyroscope: Bool { template?.interactions.contains("tilt") ?? true }

    // MARK: - KeyringViewModelProtocol: Style ID (렌티큘러 전용)
    /// 시머 효과 ID — KeyringScene이 초기 스타일 적용 시 참조
    /// 실시간 편집 업데이트는 `styleSubject`를 통해 별도로 처리됨
    /// (이름이 `Color`인 이유: `Keyring.shimmerColorId` Firestore 필드와 라벨을 맞추기 위함)
    var shimmerColorId: String? { selectedShimmerEffect.firestoreId }

    /// 테두리 효과 ID — KeyringScene이 초기 스타일 적용 시 참조
    /// (이름이 `Color`인 이유: `Keyring.borderColorId` Firestore 필드와 라벨을 맞추기 위함)
    var borderColorId: String? { selectedBorderEffect.firestoreId }

    // MARK: - Customizing Modes
    /// 렌티큘러: 시머 색상 선택 + 이펙트
    var availableCustomizingModes: [CustomizingMode] { [.style, .effect] }

    // MARK: - 초기화
    init(userManager: UserManager = UserManager.shared) {
        self.userManager = userManager
    }

    // MARK: - Style Update (시머/테두리)
    /// 시머(광택) 효과 변경 → Scene에 실시간 반영
    func updateShimmerEffect(_ effect: KeyringAppearanceColor) {
        selectedShimmerEffect = effect
        styleSubject.send(StyleUpdate(shimmer: selectedShimmerEffect, border: selectedBorderEffect))
    }

    /// 테두리 효과 변경 → Scene에 실시간 반영
    func updateBorderEffect(_ effect: KeyringAppearanceColor) {
        selectedBorderEffect = effect
        styleSubject.send(StyleUpdate(shimmer: selectedShimmerEffect, border: selectedBorderEffect))
    }

    // MARK: - View Providers
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        // 렌티큘러 VM의 availableCustomizingModes = [.style, .effect]
        // 두 모드 모두 동일한 KeyringSceneView 사용
        return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
    }

    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView {
        switch mode {
        case .style:
            return AnyView(StyleSelectorView(viewModel: self, cartItems: cartItems))
        case .effect:
            return AnyView(EffectSelectorView(viewModel: self, cartItems: cartItems))
        default:
            assertionFailure("렌티큘러 VM에서 지원하지 않는 커스터마이징 모드: \(mode)")
            return AnyView(EmptyView())
        }
    }

    func bottomViewHeightRatio(for mode: CustomizingMode) -> CGFloat {
        switch mode {
        case .style:  return 0.35
        case .effect: return 0.3
        default:      return 0.35
        }
    }

    // MARK: - Reset
    func resetCustomizingData() {
        selectedSound = nil
        selectedParticle = nil
        customSoundURL = nil
        soundId = "none"
        particleId = "none"
        downloadingItemIds.removeAll()
        downloadProgress.removeAll()
        imageA = nil
        imageB = nil
        photoScaleA = 1.0
        photoOffsetA = .zero
        photoScaleB = 1.0
        photoOffsetB = .zero
        sourceCardSize = .zero
        bodyImage = nil
        croppedImageA = nil
        croppedImageB = nil
        selectedShimmerEffect = .preset(.silver)
        selectedBorderEffect = .preset(.silver)
    }

    func resetInfoData() {
        nameText = ""
        memoText = ""
        selectedTags = []
    }

    func resetAll() {
        resetCustomizingData()
        resetInfoData()
    }
}
