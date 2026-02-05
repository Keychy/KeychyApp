//
//  BundleViewModel+Cache.swift
//  Keychy
//
//  Created by 길지훈 on 2/5/26.
//

// MARK: - BundleViewModel+Cache
//
// 캐시 및 씬 리로드 최적화
// - loadBundleImageFromCache: 캐시에서 이미지 로드
// - saveBundleImageToCache: 이미지 캐시 저장
// - shouldSkipReloadForReturnedConfig: 리로드 스킵 판단
// - updateLastConfigIds: 구성 ID 업데이트

import Foundation

extension BundleViewModel {

    // MARK: - 이미지 캐시

    /// 캐시에서 번들 이미지를 로드하여 bundleCapturedImage에 설정
    @discardableResult
    func loadBundleImageFromCache(bundle: KeyringBundle) -> Bool {
        guard let documentId = bundle.documentId else {
            print("[BundleViewModel] 번들 documentId가 없습니다.")
            return false
        }

        if let imageData = BundleImageCache.shared.load(for: documentId) {
            self.bundleCapturedImage = imageData
            print("[BundleViewModel] 캐시에서 번들 이미지 로드 성공: \(documentId)")
            return true
        } else {
            print("[BundleViewModel] 캐시에 번들 이미지가 없습니다: \(documentId)")
            return false
        }
    }

    /// 뷰모델에 저장된 뭉치 이미지를 BundleImageCache에 저장
    func saveBundleImageToCache(
        bundleId: String,
        bundleName: String,
        widgetImageData: Data? = nil,
        createdAt: Date = Date()
    ) {
        guard let imageData = bundleCapturedImage else {
            return
        }
        BundleImageCache.shared.syncBundle(
            id: bundleId,
            name: bundleName,
            fullImageData: imageData,
            widgetImageData: widgetImageData,
            createdAt: createdAt
        )
    }

    // MARK: - 씬 리로드 최적화

    /// 이전 화면에서 전달된 구성과 동일하면 씬 리로드 스킵
    ///
    /// - Returns: true면 동일 구성 → 리로드 스킵, false면 정상 로드
    ///
    /// 편집 화면에서 돌아올 때 변경사항이 없으면 씬을 다시 그리지 않음
    func shouldSkipReloadForReturnedConfig() -> Bool {
        guard let returnBGId = returnBackgroundId,
              let returnCBId = returnCarabinerId,
              let returnKRId = returnKeyringsId else {
            return false
        }

        let same = (returnBGId == lastBackgroundIdForDetail) &&
                   (returnCBId == lastCarabinerIdForDetail) &&
                   (returnKRId == lastKeyringsIdForDetail)

        if same {
            returnBackgroundId = nil
            returnCarabinerId = nil
            returnKeyringsId = nil
        }
        return same
    }

    /// BundleDetailView가 뭉치 로드를 마친 후 현재 구성 ID 저장
    func updateLastConfigIds(
        background: Background?,
        carabiner: Carabiner?,
        keyringDataList: [MultiKeyringScene.KeyringData]
    ) {
        lastBackgroundIdForDetail = makeBackgroundId(background)
        lastCarabinerIdForDetail = makeCarabinerId(carabiner)
        lastKeyringsIdForDetail = makeKeyringsId(keyringDataList)
    }
}
