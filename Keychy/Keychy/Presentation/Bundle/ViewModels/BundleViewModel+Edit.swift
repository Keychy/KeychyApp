//
//  BundleViewModel+Edit.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

// MARK: - BundleViewModel+Edit
//
// 뭉치 편집 로직
// - createKeyringDataListFromSelected: 키링 → Scene 데이터
// - convertBundleToSelectedKeyrings: 뭉치 → 편집용 변환
// - convertSelectedKeyringsToBundleFormat: 편집용 → 뭉치 변환
// - refreshEditData: 편집 화면 새로고침
// - saveBundleChanges: Firebase 저장
// - sortedKeyringsForSelection: 키링 정렬

import SwiftUI
import FirebaseFirestore

extension BundleViewModel {

    // MARK: - 키링 데이터 변환

    /// 선택된 키링들로부터 키링 데이터 리스트 생성 (편집용)
    func createKeyringDataListFromSelected(
        selectedKeyrings: [Int: Keyring],
        keyringOrder: [Int],
        carabiner: Carabiner
    ) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        for index in keyringOrder {
            guard let keyring = selectedKeyrings[index] else { continue }
            let soundId = keyring.soundId

            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()

            let particleId = keyring.particleId
            let position = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )

            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: position,
                bodyImageURL: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: particleId,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength
            )
            dataList.append(data)
        }

        return dataList
    }

    /// 뭉치에서 현재 키링들을 selectedKeyrings 형태로 변환
    func convertBundleToSelectedKeyrings(bundle: KeyringBundle) async -> ([Int: Keyring], [Int]) {
        var selectedKeyrings: [Int: Keyring] = [:]
        var keyringOrder: [Int] = []

        for (index, keyringId) in bundle.keyrings.enumerated() {
            guard keyringId != "none", !keyringId.isEmpty else { continue }

            if let keyring = self.keyring.first(where: { $0.documentId == keyringId }) {
                selectedKeyrings[index] = keyring
                keyringOrder.append(index)
            }
        }

        return (selectedKeyrings, keyringOrder)
    }

    /// selectedKeyrings를 뭉치 형태의 키링 배열로 변환
    func convertSelectedKeyringsToBundleFormat(
        selectedKeyrings: [Int: Keyring],
        maxKeyringCount: Int
    ) -> [String] {
        var keyrings = Array(repeating: "none", count: maxKeyringCount)

        for (index, keyring) in selectedKeyrings {
            if index < maxKeyringCount {
                keyrings[index] = keyring.documentId ?? "none"
            }
        }

        return keyrings
    }

    // MARK: - 데이터 새로고침

    /// 편집 화면 데이터 새로고침 (구매 상태 업데이트)
    func refreshEditData() async {
        let currentBackgroundId = newSelectedBackground?.background.id
        let currentCarabinerId = newSelectedCarabiner?.carabiner.id

        await withCheckedContinuation { continuation in
            fetchAllBackgrounds { _ in
                if let bgId = currentBackgroundId {
                    self.newSelectedBackground = self.backgroundViewData.first { $0.background.id == bgId }
                }
                continuation.resume()
            }
        }

        await withCheckedContinuation { continuation in
            fetchAllCarabiners { _ in
                if let cbId = currentCarabinerId {
                    self.newSelectedCarabiner = self.carabinerViewData.first { $0.carabiner.id == cbId }
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Firebase 저장

    /// 뭉치 변경사항을 Firebase에 저장
    func saveBundleChanges() async {
        guard let bundle = selectedBundle,
              let documentId = bundle.documentId,
              let background = newSelectedBackground,
              let carabiner = newSelectedCarabiner else {
            return
        }

        guard let backgroundId = background.background.id,
              let carabinerId = carabiner.carabiner.id else {
            return
        }

        let isBackgroundChanged = bundle.selectedBackground != backgroundId
        let isCarabinerChanged = bundle.selectedCarabiner != carabinerId

        let currentKeyrings = convertSelectedKeyringsToBundleFormat(
            selectedKeyrings: selectedKeyrings,
            maxKeyringCount: carabiner.carabiner.maxKeyringCount
        ).map { $0.isEmpty ? "none" : $0 }

        let isKeyringsChanged = bundle.keyrings != currentKeyrings

        if !isBackgroundChanged && !isCarabinerChanged && !isKeyringsChanged {
            return
        }

        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let updateData: [String: Any] = [
                "keyrings": currentKeyrings,
                "selectedBackground": backgroundId,
                "selectedCarabiner": carabinerId
            ]
            try await db.collection("KeyringBundle").document(documentId).updateData(updateData)

            await MainActor.run {
                if let index = bundles.firstIndex(where: { $0.documentId == documentId }) {
                    bundles[index].keyrings = currentKeyrings
                    bundles[index].selectedBackground = backgroundId
                    bundles[index].selectedCarabiner = carabinerId
                }

                if selectedBundle?.documentId == documentId {
                    selectedBundle?.keyrings = currentKeyrings
                    selectedBundle?.selectedBackground = backgroundId
                    selectedBundle?.selectedCarabiner = carabinerId
                }

                BundleImageCache.shared.delete(for: documentId)
            }

        } catch {
            print("❌ Firebase 업데이트 실패: \(error.localizedDescription)")
            if let firestoreError = error as NSError? {
                print("Firebase 에러 코드: \(firestoreError.code)")
                print("Firebase 에러 도메인: \(firestoreError.domain)")
                print("Firebase 에러 상세: \(firestoreError.userInfo)")
            }
        }
    }

    // MARK: - 키링 정렬 (선택 시트용)

    /// 키링 선택 시트용 정렬된 키링 리스트
    /// - 1순위: 현재 위치에 선택된 키링
    /// - 1순위: 현재 위치에 장착된 키링
    /// - 2순위: 다른 위치에 장착된 키링들
    /// - 3순위: 일반 키링들 (선택되지 않고, published/packaged 아님)
    /// - 4순위: published 또는 packaged 상태의 키링들 (맨 뒤)
    func sortedKeyringsForSelection(selectedKeyrings: [Int: Keyring], selectedPosition: Int) -> [Keyring] {
        let currentKeyring = selectedKeyrings[selectedPosition]

        return keyring.sorted { keyring1, keyring2 in
            let isKeyring1Current = keyring1.id == currentKeyring?.id
            let isKeyring2Current = keyring2.id == currentKeyring?.id

            let isKeyring1Elsewhere = selectedKeyrings.values.contains { $0.id == keyring1.id } && !isKeyring1Current
            let isKeyring2Elsewhere = selectedKeyrings.values.contains { $0.id == keyring2.id } && !isKeyring2Current

            let isKeyring1Unavailable = keyring1.status == .published || keyring1.status == .packaged
            let isKeyring2Unavailable = keyring2.status == .published || keyring2.status == .packaged

            // 1순위: 현재 위치 키링
            if isKeyring1Current != isKeyring2Current {
                return isKeyring1Current
            }

            // 2순위: 다른 위치 장착 키링
            if isKeyring1Elsewhere != isKeyring2Elsewhere {
                return isKeyring1Elsewhere
            }

            // 3순위: 일반 키링 (사용 불가 아닌 것)
            if isKeyring1Unavailable != isKeyring2Unavailable {
                return isKeyring2Unavailable
            }

            // 동일 순위면 원래 순서 유지
            guard let index1 = keyring.firstIndex(of: keyring1),
                  let index2 = keyring.firstIndex(of: keyring2) else {
                return false
            }
            return index1 < index2
        }
    }
}
