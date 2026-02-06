//
//  CollectionViewModel+Edit.swift
//  Keychy
//
//  Created by Jini on 11/6/25.
//

import SwiftUI
import FirebaseFirestore
import WidgetKit

extension CollectionViewModel {
    
    // MARK: - 키링 편집
    func updateKeyring(
        keyring: Keyring,
        name: String,
        memo: String,
        tags: [String],
        completion: @escaping (Bool) -> Void
    ) {
        guard let documentId = keyringDocumentIdByLocalId[keyring.id] else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        let updateData: [String: Any] = [
            "name": name,
            "memo": memo,
            "tags": tags
        ]
        
        
        db.collection("Keyring")
            .document(documentId)
            .updateData(updateData) { [weak self] error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                guard error == nil else { completion(false); return }

                if let index = self.keyring.firstIndex(where: { $0.id == keyring.id }) {
                    self.keyring[index].name = name
                    self.keyring[index].memo = memo
                    self.keyring[index].tags = tags

                    // 이름이 변경된 경우 App Group 메타데이터 업데이트
                    if keyring.name != name {
                        var widgetKeyrings = KeyringImageCache.shared.loadWidgetKeyrings()
                        if let keyringIndex = widgetKeyrings.firstIndex(where: { $0.id == documentId }) {
                            let existing = widgetKeyrings[keyringIndex]
                            widgetKeyrings[keyringIndex] = WidgetKeyring(
                                id: documentId,
                                name: name,
                                imagePath: existing.imagePath,
                                createdAt: existing.createdAt
                            )
                            KeyringImageCache.shared.saveWidgetKeyrings(widgetKeyrings)

                            // 위젯 타임라인 새로고침
                            WidgetCenter.shared.reloadTimelines(ofKind: "WidgetKeychy")
                        }
                    }
                }

                completion(true)
            }
    }
    
    // MARK: - 키링 삭제
    func deleteKeyring(
        uid: String,
        keyring: Keyring,
        completion: @escaping (Bool) -> Void
    ) {
        
        guard let documentId = keyringDocumentIdByLocalId[keyring.id] else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()

        // 1. Bundle 정보 조회
        db.collection("KeyringBundle")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if error != nil {
                    completion(false)
                    return
                }
                
                // 2. Batch 생성 - 모든 작업을 원자적으로 처리
                let batch = db.batch()
                
                // 2-1. Keyring 문서 삭제
                let keyringRef = db.collection("Keyring").document(documentId)
                batch.deleteDocument(keyringRef)
                
                // 2-2. User의 keyrings 배열에서 제거
                let userRef = db.collection("User").document(uid)
                batch.updateData([
                    "keyrings": FieldValue.arrayRemove([documentId])
                ], forDocument: userRef)
                
                // 2-3. Bundle에서 키링을 "none"으로 변경 및 캐시 삭제할 번들 ID 수집
                var affectedBundleIds: [String] = []
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    for document in documents {
                        guard var keyrings = document.data()["keyrings"] as? [String] else {
                            continue
                        }
                        
                        var needsUpdate = false
                        
                        // 배열을 순회하면서 keyringId를 "none"으로 변경
                        for (index, keyring) in keyrings.enumerated() {
                            if keyring == documentId {
                                keyrings[index] = "none"
                                needsUpdate = true
                            }
                        }
                        
                        if needsUpdate {
                            let bundleRef = db.collection("KeyringBundle").document(document.documentID)
                            batch.updateData(["keyrings": keyrings], forDocument: bundleRef)
                            
                            // 변경된 번들 ID 저장 (나중에 캐시 삭제용)
                            affectedBundleIds.append(document.documentID)
                        }
                    }
                }
                
                // 3. Batch 커밋 - 모든 작업이 성공하거나 모두 실패
                batch.commit { [weak self, affectedBundleIds] error in
                    guard let self = self else {
                        completion(false)
                        return
                    }
                    
                    if error != nil {
                        completion(false)
                        return
                    }
                    
                    // 4. Storage에서 키링 리소스 삭제
                    Task {
                        do {
                            try await self.deleteKeyringResources(keyring: keyring)
                            print("Storage 리소스 삭제 완료")
                        } catch {
                            print("Storage 리소스 삭제 실패: \(error.localizedDescription)")
                            // Storage 삭제 실패해도 Firestore는 이미 삭제됐으므로 계속 진행
                        }
                        
                        // 5. 로컬 데이터 정리
                        await MainActor.run {
                            if let index = self.keyring.firstIndex(where: { $0.id == keyring.id }) {
                                self.keyring.remove(at: index)
                            }

                            // 6. 매핑 Dictionary에서도 제거
                            self.keyringDocumentIdByLocalId.removeValue(forKey: keyring.id)

                            // 7. App Group 위젯용 캐시에서도 제거
                            KeyringImageCache.shared.removeKeyring(id: documentId)

                            // 8. 변경된 Bundle들의 캡처 캐시 삭제
                            for bundleId in affectedBundleIds {
                                BundleImageCache.shared.delete(for: bundleId)
                            }

                            completion(true)
                        }
                    }
                }
            }
    }
    
    // MARK: - 키링 복사
    func copyKeyring(
        uid: String,
        keyring: Keyring,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard let originalDocumentId = keyringDocumentIdByLocalId[keyring.id] else {
            completion(false, nil)
            return
        }

        let db = Firestore.firestore()
        let baseOriginalId = keyring.originalId ?? originalDocumentId

        Task {
            do {
                // Storage 리소스 재업로드
                let (newBodyImageURL, newSoundId) = try await reuploadKeyringResources(
                    bodyImage: keyring.bodyImage,
                    soundId: keyring.soundId,
                    toUserId: uid
                )

                // 새 키링 생성
                let copiedKeyring = Keyring(
                    name: keyring.name,
                    bodyImage: newBodyImageURL,
                    soundId: newSoundId,
                    particleId: keyring.particleId,
                    memo: keyring.memo,
                    tags: [],
                    createdAt: Date(),
                    authorId: uid,
                    selectedTemplate: keyring.selectedTemplate,
                    selectedRing: keyring.selectedRing,
                    selectedChain: keyring.selectedChain,
                    originalId: baseOriginalId,
                    chainLength: keyring.chainLength,
                    isNew: true,
                    hookOffsetY: keyring.hookOffsetY
                )

                // Firestore에 저장
                let docRef = db.collection("Keyring").document()
                try await docRef.setData(copiedKeyring.toDictionary())

                let newKeyringId = docRef.documentID

                // User 업데이트
                try await db.collection("User")
                    .document(uid)
                    .updateData([
                        "copyVoucher": FieldValue.increment(Int64(-1)),
                        "keyrings": FieldValue.arrayUnion([newKeyringId])
                    ])

                // 로컬 상태 업데이트
                await MainActor.run {
                    self.keyring.append(copiedKeyring)
                    self.keyringDocumentIdByLocalId[copiedKeyring.id] = newKeyringId
                    self.copyVoucher = max(0, self.copyVoucher - 1)
                }

                print("키링 복사 완료: \(keyring.name)")
                completion(true, newKeyringId)

            } catch {
                print("키링 복사 실패: \(error.localizedDescription)")
                completion(false, nil)
            }
        }
    }

    // MARK: - Storage 리소스 재업로드 (공통 헬퍼)
    func reuploadKeyringResources(
        bodyImage: String,
        soundId: String,
        toUserId uid: String
    ) async throws -> (bodyImageURL: String, soundId: String) {
        // 1. bodyImage 재업로드
        let originalImage = try await StorageManager.shared.getImage(path: bodyImage)
        let imageFileName = "\(UUID().uuidString).png"
        let imagePath = "Keyrings/BodyImages/\(uid)/\(imageFileName)"
        let newBodyImageURL = try await StorageManager.shared.uploadImage(originalImage, path: imagePath)

        // 2. soundId 재업로드 (커스텀인 경우만)
        let newSoundId: String
        if soundId.hasPrefix("https://") {
            let soundData = try await StorageManager.shared.getData(path: soundId)
            let soundFileName = "\(UUID().uuidString).m4a"
            let soundPath = "Keyrings/CustomSounds/\(uid)/\(soundFileName)"
            newSoundId = try await StorageManager.shared.uploadAudio(soundData, path: soundPath)
        } else {
            newSoundId = soundId
        }

        return (newBodyImageURL, newSoundId)
    }
    
    // MARK: - Storage에서 키링 리소스 삭제
    private func deleteKeyringResources(keyring: Keyring) async throws {
        // 1. bodyImage 삭제
        do {
            // bodyImage는 항상 URL 형식
            let bodyImagePath = extractStoragePath(from: keyring.bodyImage)
            try await StorageManager.shared.deleteFile(path: bodyImagePath)
            print("bodyImage 삭제 완료: \(bodyImagePath)")
        } catch {
            print("bodyImage 삭제 실패: \(error.localizedDescription)")
            // 파일이 이미 없을 수도 있으므로 에러를 throw하지 않고 계속 진행
        }
        // 2. soundId 삭제 (커스텀 사운드인 경우만)
        if !keyring.soundId.isEmpty && keyring.soundId.hasPrefix("https://") {
            do {
                let soundPath = extractStoragePath(from: keyring.soundId)
                try await StorageManager.shared.deleteFile(path: soundPath)
                print("customSound 삭제 완료: \(soundPath)")
            } catch {
                print("customSound 삭제 실패: \(error.localizedDescription)")
                // 파일이 이미 없을 수도 있으므로 에러를 throw하지 않고 계속 진행
            }
        }
    }
    
    // MARK: - Firebase Storage URL에서 경로 추출
    private func extractStoragePath(from url: String) -> String {
        // URL 예시:
        // https://firebasestorage.googleapis.com:443/v0/b/keychy-f6011.firebasestorage.app/o/Keyrings%2FBodyImages%2FfkhS07JxL9PTqTxOubCRD1kuhAC3%2FCE0CE156-6C8A-4F92-8889-58B9E3AB0F6D.png?alt=media&token=...
        
        // URL이 이미 경로 형식이면 그대로 반환 (혹시 모를 경우 대비)
        if !url.hasPrefix("https://") {
            return url
        }
        
        // "/o/" 이후의 부분 추출
        guard let range = url.range(of: "/o/") else {
            print("URL에서 '/o/' 부분을 찾을 수 없음: \(url)")
            return url
        }
        
        var path = String(url[range.upperBound...])
        
        // "?alt=media" 또는 "?" 이전까지 추출
        if let queryRange = path.range(of: "?") {
            path = String(path[..<queryRange.lowerBound])
        }
        
        // URL 디코딩 (%2F -> /, %20 -> 공백 등)
        guard let decodedPath = path.removingPercentEncoding else {
            print("URL 디코딩 실패: \(path)")
            return path
        }
        
        print("📍 추출된 경로: \(decodedPath)")
        return decodedPath
    }

}
