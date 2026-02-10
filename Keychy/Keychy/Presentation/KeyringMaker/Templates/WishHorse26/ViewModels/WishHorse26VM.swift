//
//  WishHorse26VM.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class WishHorse26VM: KeyringViewModelProtocol {
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
    
    // MARK: - Frame Data
    var availableFrames: [Frame] = []
    var selectedFrame: Frame? = nil
    
    // MARK: - Body Image
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0
    var isComposingText: Bool = false
    var isComposing: Bool { isComposingText }
    
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
    var templateId: String { template?.id ?? "WishHorse26" }
    var chainLength: Int { template?.chainLength ?? 3 }
    
    // MARK: - Customizing Modes
    var availableCustomizingModes: [CustomizingMode] { [.frame, .effect] }
    
    // MARK: - 초기화
    init(userManager: UserManager = UserManager.shared) {
        self.userManager = userManager
    }
    
//    // MARK: - Customizing Modes
//    var availableCustomizingModes: [CustomizingMode] {
//        [.frame, .effect]
//    }
//
//    // MARK: - View Providers
//    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
//        switch mode {
//        case .effect:
//            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
//        case .frame:
//            return AnyView(FramePreviewView(viewModel: self, onSceneReady: onSceneReady))
//        default:
//            return AnyView(EmptyView())
//        }
//    }
//
//    func bottomContentView(
//        for mode: CustomizingMode,
//        showPurchaseSheet: Binding<Bool>,
//        cartItems: Binding<[EffectItem]>
//    ) -> AnyView {
//        switch mode {
//        case .effect:
//            return AnyView(EffectSelectorView(viewModel: self, cartItems: cartItems))
//        case .frame:
//            return AnyView(FrameSelectorView(viewModel: self))
//        default:
//            return AnyView(EmptyView())
//        }
//    }
//
//    func bottomViewHeightRatio(for mode: CustomizingMode) -> CGFloat {
//        switch mode {
//        case .frame:
//            return 0.3  // 프레임 모드는 더 낮은 높이
//        case .effect:
//            return 0.3  // 이펙트 모드도 같은 높이
//        default:
//            return 0.35
//        }
//    }
    
    // MARK: - Reset
    func resetCustomizingData() {
        selectedSound = nil
        selectedParticle = nil
        customSoundURL = nil
        soundId = "none"
        particleId = "none"
        downloadingItemIds.removeAll()
        downloadProgress.removeAll()
        selectedFrame = nil
        bodyImage = nil
        availableFrames.removeAll()
        isComposingText = false
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
