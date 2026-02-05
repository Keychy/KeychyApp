//
//  BundleViewModel+Helpers.swift
//  Keychy
//
//  Created by 길지훈 on 2/5/26.
//

// MARK: - BundleViewModel+Helpers
//
// 유틸리티 메서드
// - resolveBackground/Carabiner: ID → 모델 변환
// - makeBackgroundId/CarabinerId/KeyringsId: 구성 ID 생성
// - addBackgroundToUser/addCarabinerToUser: 사용자 아이템 추가

import FirebaseFirestore

extension BundleViewModel {

    // MARK: - ID → Model 변환

    func resolveBackground(from id: String) -> Background? {
        backgrounds.first { $0.id == id }
    }

    func resolveCarabiner(from id: String) -> Carabiner? {
        carabiners.first { $0.id == id }
    }

    // MARK: - 구성 ID 생성 (씬 리로드 판단용)

    func makeBackgroundId(_ bg: Background?) -> String {
        guard let bg else { return "" }
        return bg.id ?? ""
    }

    func makeCarabinerId(_ cb: Carabiner?) -> String {
        guard let cb else { return "" }
        return "\(cb.id ?? "")|\(cb.carabinerX)|\(cb.carabinerY)|\(cb.carabinerWidth)"
    }

    func makeKeyringsId(_ list: [MultiKeyringScene.KeyringData]) -> String {
        list
            .sorted(by: { $0.index < $1.index })
            .map { item in
                "\(item.index)|\(item.bodyImageURL)|\((item.templateId ?? ""))|\(item.soundId)|\(item.particleId)|\((item.hookOffsetY ?? 0))|\(item.chainLength)"
            }
            .joined(separator: ";")
    }

    // MARK: - 사용자 아이템 추가

    /// User의 backgrounds 배열에 새 배경 추가
    func addBackgroundToUser(backgroundName: String, userManager: UserManager) async -> Bool {
        guard let userId = userManager.currentUser?.id else {
            print("사용자 ID를 가져올 수 없습니다")
            return false
        }

        let db = FirebaseFirestore.Firestore.firestore()
        let userRef = db.collection("User").document(userId)

        do {
            try await userRef.updateData([
                "backgrounds": FirebaseFirestore.FieldValue.arrayUnion([backgroundName])
            ])

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                userManager.loadUserInfo(uid: userId) { _ in
                    continuation.resume()
                }
            }

            print("User backgrounds 업데이트 완료: \(backgroundName)")
            return true

        } catch {
            print("User backgrounds 업데이트 에러: \(error.localizedDescription)")
            return false
        }
    }

    /// User의 카라비너에 새 카라비너 추가
    func addCarabinerToUser(carabinerName: String, userManager: UserManager) async -> Bool {
        guard let userId = userManager.currentUser?.id else {
            print("사용자 ID를 가져올 수 없습니다")
            return false
        }

        let db = FirebaseFirestore.Firestore.firestore()
        let userRef = db.collection("User").document(userId)

        do {
            try await userRef.updateData([
                "carabiners": FirebaseFirestore.FieldValue.arrayUnion([carabinerName])
            ])

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                userManager.loadUserInfo(uid: userId) { _ in
                    continuation.resume()
                }
            }

            print("User carabiners 업데이트 완료: \(carabinerName)")
            return true

        } catch {
            print("User carabiners 업데이트 에러: \(error.localizedDescription)")
            return false
        }
    }
}
