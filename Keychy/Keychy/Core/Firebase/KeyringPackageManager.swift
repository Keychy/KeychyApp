//
//  KeyringPackageManager.swift
//  Keychy
//
//  키링 선물 포장 로직 (Collection, Workshop 공용)
//

import Foundation
import FirebaseFirestore

/// 키링 선물 포장 관리자
enum KeyringPackageManager {

    // MARK: - 키링 포장하기

    /// 키링을 선물용으로 포장합니다.
    /// - Parameters:
    ///   - uid: 사용자 ID
    ///   - keyringDocumentId: 키링 Firestore Document ID
    ///   - completion: 완료 콜백 (성공 여부, PostOffice ID, Share Link)
    static func packageKeyring(
        uid: String,
        keyringDocumentId: String,
        completion: @escaping (Bool, String?, String?) -> Void
    ) {
        let db = Firestore.firestore()

        // 1. Keyring 상태 업데이트 (isPackaged = true)
        db.collection("Keyring")
            .document(keyringDocumentId)
            .updateData(["isPackaged": true]) { error in
                if let error = error {
                    print("[Package] Keyring 상태 업데이트 실패: \(error.localizedDescription)")
                    completion(false, nil, nil)
                    return
                }

                print("[Package] Keyring 상태 업데이트 완료")

                // 2. PostOffice 문서 생성
                createPostOffice(
                    db: db,
                    uid: uid,
                    keyringDocumentId: keyringDocumentId,
                    completion: completion
                )
            }
    }

    // MARK: - Private Helpers

    /// PostOffice 문서 생성
    private static func createPostOffice(
        db: Firestore,
        uid: String,
        keyringDocumentId: String,
        completion: @escaping (Bool, String?, String?) -> Void
    ) {
        let postOfficeRef = db.collection("PostOffice").document()
        let postOfficeId = postOfficeRef.documentID

        // 중복 체크 (희귀 케이스)
        postOfficeRef.getDocument { checkSnapshot, checkError in
            if checkSnapshot?.exists == true {
                print("[Package] PostOffice ID 중복 발견 - 재시도")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    packageKeyring(uid: uid, keyringDocumentId: keyringDocumentId, completion: completion)
                }
                return
            }

            // 공유 링크 생성
            guard let shareLink = DeepLinkManager.createShareLink(postOfficeId: postOfficeId) else {
                print("[Package] 공유 링크 생성 실패")
                completion(false, nil, nil)
                return
            }

            let shareLinkString = shareLink.absoluteString
            print("[Package] 공유 링크 생성: \(shareLinkString)")

            // PostOffice 문서 데이터
            let postOfficeData: [String: Any] = [
                "type": "receive",
                "senderId": uid,
                "keyringId": keyringDocumentId,
                "shareLink": shareLinkString,
                "createdAt": Timestamp(date: Date())
            ]

            // 문서 생성
            postOfficeRef.setData(postOfficeData) { error in
                if let error = error {
                    print("[Package] PostOffice 문서 생성 실패: \(error.localizedDescription)")
                    completion(false, nil, nil)
                    return
                }

                print("[Package] PostOffice 문서 생성 완료: \(postOfficeId)")

                // Bundle에서 키링 제거
                removeKeyringFromBundles(db: db, uid: uid, keyringDocumentId: keyringDocumentId) { _ in
                    completion(true, postOfficeId, shareLinkString)
                }
            }
        }
    }

    /// Bundle에서 키링 제거
    private static func removeKeyringFromBundles(
        db: Firestore,
        uid: String,
        keyringDocumentId: String,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection("KeyringBundle")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { snapshot, error in
                if error != nil {
                    completion(false)
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("[Package] Bundle 없음")
                    completion(true)
                    return
                }

                let batch = db.batch()
                var affectedBundleIds: [String] = []

                for document in documents {
                    guard var keyrings = document.data()["keyrings"] as? [String] else {
                        continue
                    }

                    var needsUpdate = false

                    for (index, keyring) in keyrings.enumerated() {
                        if keyring == keyringDocumentId {
                            keyrings[index] = "none"
                            needsUpdate = true
                        }
                    }

                    if needsUpdate {
                        let bundleRef = db.collection("KeyringBundle").document(document.documentID)
                        batch.updateData(["keyrings": keyrings], forDocument: bundleRef)
                        affectedBundleIds.append(document.documentID)
                    }
                }

                if affectedBundleIds.isEmpty {
                    completion(true)
                    return
                }

                batch.commit { error in
                    if let error = error {
                        print("[Package] Bundle 업데이트 실패: \(error.localizedDescription)")
                        completion(false)
                        return
                    }

                    print("[Package] \(affectedBundleIds.count)개 Bundle에서 키링 제거 완료")

                    // Bundle 캡처 캐시 삭제
                    for bundleId in affectedBundleIds {
                        BundleImageCache.shared.delete(for: bundleId)
                    }

                    completion(true)
                }
            }
    }
}
