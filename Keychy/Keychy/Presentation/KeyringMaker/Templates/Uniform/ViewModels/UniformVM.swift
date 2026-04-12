//
//  UniformVM.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class UniformVM: KeyringViewModelProtocol {
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

    // MARK: - Uniform Color Data
    var uniformColor1: Color = .black    // 패턴(mask) 영역 색상
    var uniformColor2: Color = .white    // 베이스 영역 색상

    // MARK: - Uniform Text Data (등번호 + 이름)
    var numberText: String = ""        // 등번호 (0~99)
    var playerNameText: String = ""    // 이름 (한글/영문, 8자)

    // MARK: - Marking Data (마킹 탭)
    var numberInnerColor: Color = .white       // 등번호 내부 색상
    var numberOutlineColor: Color = .black     // 등번호 테두리 색상
    var nameInnerColor: Color = .white         // 이름 내부 색상
    var nameOutlineColor: Color = .black       // 이름 테두리 색상
    var textCurvature: CGFloat = 0.0           // 글자 곡률 (0 = 직선)

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
    var templateId: String { template?.id ?? "Uniform" }
    var chainLength: Int { 3 }

    // MARK: - Customizing Modes
    var availableCustomizingModes: [CustomizingMode] { [.frame, .marking, .effect] }

    // MARK: - 초기화
    init(userManager: UserManager = UserManager.shared) {
        self.userManager = userManager
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
        uniformColor1 = .black
        uniformColor2 = .white
        numberText = ""
        playerNameText = ""
        numberInnerColor = .white
        numberOutlineColor = .black
        nameInnerColor = .white
        nameOutlineColor = .black
        textCurvature = 0.0
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
