//
//  WelcomeKeyringViewModel.swift
//  Keychy
//
//  Created by 길지훈 on 11/11/25.
//

import SwiftUI
import Combine

@Observable
class WelcomeKeyringViewModel: KeyringViewModelProtocol {
    var nameText: String
    var memoText: String = ""
    var maxTextCount: Int = 10
    var maxMemoCount: Int = 100
    var createdAt: Date = Date()
    var selectedTags: [String] = []

    var bodyImage: UIImage?
    var hookOffsetY: CGFloat = 0.0

    /// 템플릿 ID
    var templateId: String {
        "Welcome"
    }

    var availableCustomizingModes: [CustomizingMode] = []

    var availableSounds: [Sound] = []
    var availableParticles: [Particle] = []
    var sortedAvailableSounds: [Sound] { [] }
    var sortedAvailableParticles: [Particle] { [] }
    var selectedSound: Sound? = nil
    var selectedParticle: Particle? = nil
    var customSoundURL: URL? = nil
    var hasCustomSound: Bool { false }
    var downloadingItemIds: Set<String> = []
    var downloadProgress: [String: Double] = [:]

    var soundId: String = "none"
    var particleId: String = "PurpleSparkle"
    var effectSubject = PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never>()

    var savedKeyringDocumentId: String?
    var packagedPostOfficeId: String?
    var packagedShareLink: String?

    init(nickname: String, bodyImage: UIImage) {
        self.nameText = nickname
        self.bodyImage = bodyImage
    }

    func updateSound(_ sound: Sound?) {}
    func updateParticle(_ particle: Particle?) {}
    func applyCustomSound(_ url: URL) {}
    func removeCustomSound() {}
    func fetchEffects() async {}

    func isOwned(soundId: String) -> Bool { false }
    func isOwned(particleId: String) -> Bool { false }

    func isInBundle(soundId: String) -> Bool {
        EffectManager.shared.isInBundle(soundId: soundId)
    }
    func isInBundle(particleId: String) -> Bool {
        EffectManager.shared.isInBundle(particleId: particleId)
    }

    func isInCache(soundId: String) -> Bool {
        EffectManager.shared.isInCache(soundId: soundId)
    }
    func isInCache(particleId: String) -> Bool {
        EffectManager.shared.isInCache(particleId: particleId)
    }

    func downloadSound(_ sound: Sound) async {}
    func downloadParticle(_ particle: Particle) async {}

    func resetCustomizingData() {}
    func resetInfoData() {}
    func resetAll() {}
}
