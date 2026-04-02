//
//  LenticularVM+Firebase.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import SwiftUI
import FirebaseFirestore

extension LenticularVM {
    // MARK: - Firebase Template 가져오기
    func fetchTemplate() async {
        isLoadingTemplate = true
        defer { isLoadingTemplate = false }

        do {
            let document = try await Firestore.firestore()
                .collection("Template")
                .document("Lenticular")
                .getDocument()

            template = try document.data(as: KeyringTemplate.self)
            hookOffsetY = template?.hookOffsetY ?? 0.0

        } catch {
            errorMessage = "템플릿을 불러오는데 실패했습니다."
        }
    }

    // MARK: - Firebase Effects 가져오기
    func fetchEffects() async {
        guard let user = userManager.currentUser else {
            errorMessage = "유저 정보를 불러올 수 없습니다."
            return
        }

        do {
            // Sound 전체 가져오기
            let soundsSnapshot = try await Firestore.firestore()
                .collection("Sound")
                .activeItems()

            let allSounds = try soundsSnapshot.documents.compactMap {
                try $0.data(as: Sound.self)
            }

            let ownedSounds = allSounds.filter { sound in
                guard let id = sound.id else { return false }
                return user.soundEffects.contains(id)
            }
            let notOwnedSounds = allSounds.filter { sound in
                guard let id = sound.id else { return false }
                return !user.soundEffects.contains(id)
            }

            availableSounds = ownedSounds + notOwnedSounds

            // Particle 전체 가져오기
            let particlesSnapshot = try await Firestore.firestore()
                .collection("Particle")
                .activeItems()

            let allParticles = try particlesSnapshot.documents.compactMap {
                try $0.data(as: Particle.self)
            }

            let ownedParticles = allParticles.filter { particle in
                guard let id = particle.id else { return false }
                return user.particleEffects.contains(id)
            }
            let notOwnedParticles = allParticles.filter { particle in
                guard let id = particle.id else { return false }
                return !user.particleEffects.contains(id)
            }

            availableParticles = ownedParticles + notOwnedParticles

        } catch {
            errorMessage = "이펙트 목록을 불러오는데 실패했습니다."
        }
    }
}
