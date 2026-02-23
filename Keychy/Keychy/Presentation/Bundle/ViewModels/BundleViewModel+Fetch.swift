//
//  BundleViewModel+Fetch.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

// MARK: - BundleViewModel+Fetch
//
// Firebase 데이터 읽기
// - fetchAllBundles: 사용자 뭉치 로드
// - fetchAllBackgrounds: 배경 로드
// - fetchAllCarabiners: 카라비너 로드
// - fetchKeyringInfo: 키링 정보 로드

import FirebaseFirestore

extension BundleViewModel {

    // MARK: - 사용자의 모든 뭉치 로드

    func fetchAllBundles(uid: String, completion: @escaping (Bool) -> Void) {
        isLoading = true

        db.collection("KeyringBundle")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }

                defer { self.isLoading = false }

                if let error = error {
                    print("뭉치 로드 에러: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("뭉치 문서가 없습니다.")
                    self.bundles = []
                    completion(true)
                    return
                }

                let loadedBundles: [KeyringBundle] = documents.compactMap { doc in
                    KeyringBundle(documentId: doc.documentID, data: doc.data())
                }

                self.bundles = loadedBundles
                completion(true)
            }
    }

    // MARK: - 전체 배경 로드 + 소유 여부 표시

    func fetchAllBackgrounds(completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            await dataManager.fetchBackgroundsIfNeeded()

            let items = backgrounds
            let ownedIds = UserManager.shared.currentUser?.backgrounds ?? []
            let decorated = items.map { bg in
                BackgroundViewData(background: bg, isOwned: ownedIds.contains(bg.id ?? ""))
            }

            // Lottie 배경 JSON 다운로드 (뷰 렌더링 전 완료 보장)
            let lottieBackgrounds = items.filter { $0.isLottie }
            for bg in lottieBackgrounds {
                await LottieItemManager.shared.downloadBackgroundLottie(bg)
            }

            await MainActor.run {
                self.backgroundViewData = decorated
                self.isLoading = false
                completion(true)
            }
        }
    }

    // MARK: - 전체 카라비너 로드 + 소유 여부 표시

    func fetchAllCarabiners(completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            await dataManager.fetchCarabinersIfNeeded()

            let items = carabiners
            let ownedIds = UserManager.shared.currentUser?.carabiners ?? []
            let decorated = items.map { cb in
                CarabinerViewData(carabiner: cb, isOwned: ownedIds.contains(cb.id ?? ""))
            }

            // Lottie 카라비너 JSON 다운로드 (뷰 렌더링 전 완료 보장)
            let lottieCarabiners = items.filter { $0.isLottie }
            for cb in lottieCarabiners {
                await LottieItemManager.shared.downloadCarabinerLottie(cb)
            }

            await MainActor.run {
                self.carabinerViewData = decorated
                self.isLoading = false
                completion(true)
            }
        }
        selectedCarabiner = carabiners.first
    }

    // MARK: - 단일 키링 정보 로드

    func fetchKeyringInfo(keyringId: String) async -> KeyringInfo? {
        do {
            let document = try await db.collection("Keyring").document(keyringId).getDocument()

            guard let data = document.data(),
                  let bodyImage = data["bodyImage"] as? String,
                  let soundId = data["soundId"] as? String,
                  let particleId = data["particleId"] as? String else {
                return nil
            }

            let hookOffsetY = data["hookOffsetY"] as? CGFloat ?? 0.0
            let chainLength = data["chainLength"] as? Int ?? 5
            let selectedTemplate = data["selectedTemplate"] as? String

            return KeyringInfo(
                id: keyringId,
                bodyImage: bodyImage,
                selectedTemplate: selectedTemplate,
                soundId: soundId,
                particleId: particleId,
                hookOffsetY: hookOffsetY,
                chainLength: chainLength
            )
        } catch {
            return nil
        }
    }
}
