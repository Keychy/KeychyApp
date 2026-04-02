//
//  BundleViewModel+CRUD.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

// MARK: - BundleViewModel+CRUD
//
// Firebase 데이터 쓰기
// - createBundle: 뭉치 생성
// - createKeyringDataList: 키링 → Scene 데이터 변환
// - updateBundleMainStatus: 대표 뭉치 설정
// - updateBundleName: 이름 변경
// - incrementUseCount: 사용 횟수 증가

import FirebaseFirestore

extension BundleViewModel {
    //MARK: - 새 뭉치 생성 및 파베에 업로드
    func createBundle(
        userId: String,
        name: String,
        selectedBackground: String,
        selectedCarabiner: String,
        keyrings: [String],
        keyringOrder: [Int],
        maxKeyrings: Int,
        isMain: Bool,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let newBundle = KeyringBundle(
            userId: userId,
            name: name,
            selectedBackground: selectedBackground,
            selectedCarabiner: selectedCarabiner,
            keyrings: keyrings,
            keyringOrder: keyringOrder,
            maxKeyrings: maxKeyrings,
            isMain: isMain,
            createdAt: Date()
        )
        
        let bundleData = newBundle.toDictionary()
        
        // Firestore가 자동 생성한 문서 ID 사용
        let docRef = db.collection("KeyringBundle").document()
        
        docRef.setData(bundleData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("뭉치 생성 에러 : \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            let bundleId = docRef.documentID
            
            // 로컬 번들 목록에 추가 (documentId 포함)
            DispatchQueue.main.async {
                var updatedBundle = newBundle
                updatedBundle.documentId = bundleId
                self.bundles.append(updatedBundle)

                self.incrementUseCount(
                    carabinerId: selectedCarabiner,
                    backgroundId: selectedBackground
                )

                // 메인 뭉치로 생성된 경우 홈 화면 리프레시 필요
                if isMain {
                    HomeViewModel.needsRefresh = true
                }

                // 첫 뭉치 생성 체크 (기본 1개 → 사용자가 만든 첫 뭉치는 2개일 때)
                let isFirstUserBundle = self.bundles.count == 2
                ReviewManager.shared.checkFirstBundle(isFirstBundle: isFirstUserBundle)

                print("뭉치 생성 완료: \(bundleId)")
                completion(true, bundleId)
            }
        }
    }
    
    /// 뭉치의 키링들을 MultiKeyringScene.KeyringData 배열로 변환
    /// keyringOrder가 있으면 장착 순서대로, 없으면 슬롯 index 순서로 fallback
    func createKeyringDataList(bundle: KeyringBundle, carabiner: Carabiner) async -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []
        
        // keyringOrder가 있으면 장착 순서 기반, 없으면 슬롯 index 순 fallback
        let orderedIndices: [Int]
        if !bundle.keyringOrder.isEmpty {
            orderedIndices = bundle.keyringOrder
        } else {
            orderedIndices = bundle.keyrings.indices
                .filter { bundle.keyrings[$0] != "none" && !bundle.keyrings[$0].isEmpty }
                .sorted()
        }
        
        for slotIndex in orderedIndices {
            guard slotIndex < carabiner.maxKeyringCount,
                  slotIndex < bundle.keyrings.count else { continue }

            let keyringId = bundle.keyrings[slotIndex]
            guard keyringId != "none", !keyringId.isEmpty else { continue }

            guard let keyringInfo = await fetchKeyringInfo(keyringId: keyringId) else { continue }
            
            // 커스텀 사운드 URL 처리 (HTTP/HTTPS로 시작하는 경우)
            let customSoundURL: URL? = {
                if keyringInfo.soundId.hasPrefix("https://") || keyringInfo.soundId.hasPrefix("http://") {
                    return URL(string: keyringInfo.soundId)
                }
                return nil
            }()
            
            // KeyringData 생성
            let data = MultiKeyringScene.KeyringData(
                index: slotIndex,
                position: CGPoint(
                    x: carabiner.keyringXPosition[slotIndex],
                    y: carabiner.keyringYPosition[slotIndex]
                ),
                bodyImageURL: keyringInfo.bodyImage,
                templateId: keyringInfo.selectedTemplate,
                soundId: keyringInfo.soundId,
                customSoundURL: customSoundURL,
                particleId: keyringInfo.particleId,
                hookOffsetY: keyringInfo.hookOffsetY,
                chainLength: keyringInfo.chainLength,
                isGyroscope: keyringInfo.isGyroscope,
                shimmerColorId: keyringInfo.shimmerColorId,
                borderColorId: keyringInfo.borderColorId
            )
            dataList.append(data)
        }

        return dataList
    }
    
    //MARK: - 메인 번들 업데이트 (기존 메인 해제 포함)
    func updateBundleMainStatus(bundle: KeyringBundle, isMain: Bool, completion: @escaping (Bool) -> Void) {
        guard let documentId = bundle.documentId else {
            completion(false)
            return
        }
        
        // 새로운 번들을 메인으로 설정하는 경우, 기존 메인 번들을 먼저 해제
        if isMain {
            // 현재 메인인 다른 번들들을 찾아서 해제
            let currentMainBundles = bundles.filter { $0.isMain && $0.documentId != bundle.documentId }
            
            let dispatchGroup = DispatchGroup()
            var hasError = false
            
            // 기존 메인 번들들을 모두 해제
            for mainBundle in currentMainBundles {
                guard let mainDocId = mainBundle.documentId else { continue }
                
                dispatchGroup.enter()
                db.collection("KeyringBundle").document(mainDocId).updateData([
                    "isMain": false
                ]) { error in
                    if error != nil {
                        hasError = true
                    }
                    dispatchGroup.leave()
                }
            }
            
            // 모든 기존 메인 번들 해제 완료 후, 새로운 메인 번들 설정
            dispatchGroup.notify(queue: .main) {
                if hasError {
                    completion(false)
                    return
                }
                
                // 새로운 번들을 메인으로 설정
                self.db.collection("KeyringBundle").document(documentId).updateData([
                    "isMain": isMain
                ]) { [weak self] error in
                    self?.handleMainBundleUpdateCompletion(
                        error: error,
                        bundle: bundle,
                        isMain: isMain,
                        currentMainBundles: currentMainBundles,
                        completion: completion
                    )
                }
            }
        } else {
            // 메인 해제하는 경우는 단순히 업데이트
            db.collection("KeyringBundle").document(documentId).updateData([
                "isMain": isMain
            ]) { [weak self] error in
                self?.handleMainBundleUpdateCompletion(
                    error: error,
                    bundle: bundle,
                    isMain: isMain,
                    currentMainBundles: [],
                    completion: completion
                )
            }
        }
    }
    
    func handleMainBundleUpdateCompletion(
        error: Error?,
        bundle: KeyringBundle,
        isMain: Bool,
        currentMainBundles: [KeyringBundle],
        completion: @escaping (Bool) -> Void
    ) {
        if let error = error {
            print("메인 번들 업데이트 에러: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        // 로컬 상태 업데이트
        DispatchQueue.main.async {
            // 기존 메인 번들들을 로컬에서도 해제
            for mainBundle in currentMainBundles {
                if let index = self.bundles.firstIndex(where: { $0.documentId == mainBundle.documentId }) {
                    self.bundles[index].isMain = false
                }
            }
            
            // 현재 번들 상태 업데이트
            if let index = self.bundles.firstIndex(where: { $0.documentId == bundle.documentId }) {
                self.bundles[index].isMain = isMain
                // selectedBundle도 같은 번들이면 업데이트
                if self.selectedBundle?.documentId == bundle.documentId {
                    self.selectedBundle?.isMain = isMain
                }

                // 대표 뭉치 변경 시 홈 화면 리프레시 필요
                HomeViewModel.needsRefresh = true
            }
            completion(true)
        }
    }
    
    //MARK: - 번들 이름 업데이트
    func updateBundleName(bundle: KeyringBundle, newName: String, completion: @escaping (Bool) -> Void) {
        guard let documentId = bundle.documentId else {
            completion(false)
            return
        }
        
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collection("KeyringBundle").document(documentId).updateData([
            "name": trimmedName
        ]) { [weak self] error in
            if error != nil {
                completion(false)
                return
            }
            
            // 로컬 상태 업데이트
            DispatchQueue.main.async {
                if let index = self?.bundles.firstIndex(where: { $0.documentId == bundle.documentId }) {
                    self?.bundles[index].name = trimmedName
                }
                
                // selectedBundle도 같은 번들이면 업데이트
                if self?.selectedBundle?.documentId == bundle.documentId {
                    self?.selectedBundle?.name = trimmedName
                }
                completion(true)
            }
        }
    }

    // MARK: - 사용 횟수 증가

    /// 배경, 카라비너의 사용 횟수를 증가시키는 메서드
    func incrementUseCount(
        carabinerId: String?,
        backgroundId: String?
    ) {
        if let carabinerId = carabinerId, !carabinerId.isEmpty {
            db.collection("Carabiner")
                .document(carabinerId)
                .updateData([
                    "useCount": FieldValue.increment(Int64(1))
                ]) { error in
                    if let error = error {
                        print("[useCount] Carabiner 증가 실패: \(error)")
                    } else {
                        print("[useCount] Carabiner 증가 성공: \(carabinerId)")
                    }
                }
        }

        if let backgroundId = backgroundId, !backgroundId.isEmpty {
            db.collection("Background")
                .document(backgroundId)
                .updateData([
                    "useCount": FieldValue.increment(Int64(1))
                ]) { error in
                    if let error = error {
                        print("[useCount] Background 증가 실패: \(error)")
                    } else {
                        print("[useCount] Background 증가 성공: \(backgroundId)")
                    }
                }
        }
    }
}
