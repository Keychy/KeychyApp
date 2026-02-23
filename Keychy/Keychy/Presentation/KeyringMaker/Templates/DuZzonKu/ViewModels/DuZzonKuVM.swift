//
//  DuZzonKuVM.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class DuZzonKuVM: KeyringViewModelProtocol {
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
    
    // MARK: - Photo Data
    var selectedPhotoImage: UIImage? = nil
    var photoImages: [Int: UIImage] = [:] // 인덱스별 사진 저장
    
    // MARK: - Photo Transform State (인덱스별)
    var photoScales: [Int: CGFloat] = [:]
    var photoRotations: [Int: Angle] = [:]
    var photoOffsets: [Int: CGSize] = [:]
    
    // 특정 인덱스의 변환 값 가져오기 (기본값 반환)
    func getPhotoScale(at index: Int) -> CGFloat {
        return photoScales[index] ?? 1.0
    }
    
    func getPhotoRotation(at index: Int) -> Angle {
        return photoRotations[index] ?? .zero
    }
    
    func getPhotoOffset(at index: Int) -> CGSize {
        return photoOffsets[index] ?? .zero
    }
    
    // 특정 인덱스의 변환 값 설정
    func setPhotoScale(_ scale: CGFloat, at index: Int) {
        photoScales[index] = scale
    }
    
    func setPhotoRotation(_ rotation: Angle, at index: Int) {
        photoRotations[index] = rotation
    }
    
    func setPhotoOffset(_ offset: CGSize, at index: Int) {
        photoOffsets[index] = offset
    }
    
    // MARK: - Body Image
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0
    var isComposingPhoto: Bool = false
    var isComposing: Bool { isComposingPhoto }
    
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
    var templateId: String { template?.id ?? "DuZzonKu" }
    var chainLength: Int { template?.chainLength ?? 3 }
    
    // MARK: - Customizing Modes
    var availableCustomizingModes: [CustomizingMode] { [.frame, .effect] }
    
    // MARK: - 초기화
    init(userManager: UserManager = UserManager.shared) {
        self.userManager = userManager
    }
    
    // MARK: - Photo Management (여러 개 지원)
    /// 특정 인덱스의 사진 가져오기
    func getPhoto(at index: Int) -> UIImage? {
        return photoImages[index]
    }
    
    /// 특정 인덱스에 사진 저장
    func setPhoto(_ image: UIImage, at index: Int) {
        photoImages[index] = image
        // 첫 번째 사진은 selectedPhotoImage에도 저장 (하위 호환성)
        if index == 0 {
            selectedPhotoImage = image
        }
    }
    
    /// 특정 인덱스의 사진 제거
    func removePhoto(at index: Int) {
        photoImages.removeValue(forKey: index)
        // 변환 값도 제거
        photoScales.removeValue(forKey: index)
        photoRotations.removeValue(forKey: index)
        photoOffsets.removeValue(forKey: index)
        
        if index == 0 {
            selectedPhotoImage = nil
        }
    }
    
    // MARK: - View Providers
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
        case .frame:
            return AnyView(DuZzonKuFramePreviewView(viewModel: self, onSceneReady: onSceneReady))
        default:
            return AnyView(EmptyView())
        }
    }

    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(EffectSelectorView(viewModel: self, cartItems: cartItems))
        case .frame:
            return AnyView(DuZzonKuFrameSelectorView(viewModel: self))
        default:
            return AnyView(EmptyView())
        }
    }

    func bottomViewHeightRatio(for mode: CustomizingMode) -> CGFloat {
        switch mode {
        case .frame:
            return 0.28  // 프레임 모드는 더 낮은 높이
        case .effect:
            return 0.3  // 이펙트 모드도 같은 높이
        default:
            return 0.35
        }
    }
    
    // MARK: - Lifecycle Callbacks
    /// 모드 변경 시 프레임 → 다른 모드로 전환되면 사진과 프레임 합성
    func onModeChanged(from oldMode: CustomizingMode, to newMode: CustomizingMode) {
        if oldMode == .frame && newMode != .frame {
            Task {
                await composePhotoWithFrame()
            }
        }
    }

    /// 다음 화면으로 이동하기 전 사진과 프레임 합성
    func beforeNavigateToNext() {
        Task {
            await composePhotoWithFrame()
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
        selectedFrame = nil
        selectedPhotoImage = nil
        photoImages.removeAll()
        photoScales.removeAll()
        photoRotations.removeAll()
        photoOffsets.removeAll()
        bodyImage = nil
        availableFrames.removeAll()
        isComposingPhoto = false
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
