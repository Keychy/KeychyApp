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
    /// 선택된 시머(광택) 색상
    var selectedShimmerColor: KeyringAppearanceColor = .preset(.silver)
    /// 선택된 테두리 색상
    var selectedBorderColor: KeyringAppearanceColor = .preset(.silver)

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

    // MARK: - Body Image
    /// A+B 가로 합성 아틀라스 (셰이더가 UV로 좌/우 분리 샘플링)
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0

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
    /// 시머 색상 ID — KeyringScene이 초기 스타일 적용 시 참조
    /// 실시간 편집 업데이트는 `styleSubject`를 통해 별도로 처리됨
    var shimmerColorId: String? { selectedShimmerColor.firestoreId }

    /// 테두리 색상 ID — KeyringScene이 초기 스타일 적용 시 참조
    var borderColorId: String? { selectedBorderColor.firestoreId }

    // MARK: - Customizing Modes
    /// 렌티큘러: 시머 색상 선택 + 이펙트
    var availableCustomizingModes: [CustomizingMode] { [.style, .effect] }

    // MARK: - 초기화
    init(userManager: UserManager = UserManager.shared) {
        self.userManager = userManager
    }

    // MARK: - Style Update (시머/테두리)
    /// 시머(광택) 색상 변경 → Scene에 실시간 반영
    func updateShimmerColor(_ color: KeyringAppearanceColor) {
        selectedShimmerColor = color
        styleSubject.send(StyleUpdate(shimmer: selectedShimmerColor, border: selectedBorderColor))
    }

    /// 테두리 색상 변경 → Scene에 실시간 반영
    func updateBorderColor(_ color: KeyringAppearanceColor) {
        selectedBorderColor = color
        styleSubject.send(StyleUpdate(shimmer: selectedShimmerColor, border: selectedBorderColor))
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
            return AnyView(StyleSelectorView(viewModel: self))
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
        bodyImage = nil
        selectedShimmerColor = .preset(.silver)
        selectedBorderColor = .preset(.silver)
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
