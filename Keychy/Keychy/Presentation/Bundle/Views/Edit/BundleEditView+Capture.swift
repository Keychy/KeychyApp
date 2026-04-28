//
//  BundleEditView+Capture.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI

// MARK: - 키링 데이터 및 캡처
extension BundleEditView {

    /// 키링 데이터 리스트 업데이트
    func updateKeyringDataList() {
        guard let carabiner = bundleVM.newSelectedCarabiner?.carabiner else {
            keyringDataList = []
            return
        }

        let newData = bundleVM.createKeyringDataListFromSelected(
            selectedKeyrings: bundleVM.selectedKeyrings,
            keyringOrder: bundleVM.keyringOrder,
            carabiner: carabiner
        )

        // 데이터가 실제로 변경된 경우에만 업데이트
        if keyringDataList != newData {
            keyringDataList = newData

            // 키링이 추가/변경될 때도 씬을 새로고침하여 확실히 반영되도록 함
            if !newData.isEmpty {
                sceneRefreshId = UUID()
            }
        }
    }

    // MARK: - 썸네일 재캡쳐 & 캐시 저장
    func recaptureAndCacheBundleThumbnail(bundleId: String, bundleName: String, createdAt: Date) async {
        // 편집 중 상태로 캡쳐
        guard let bg = bundleVM.newSelectedBackground?.background,
              let cb = bundleVM.newSelectedCarabiner?.carabiner else {
            return
        }

        await MainActor.run {
            isCapturing = true
        }

        // 캡쳐용 키링 데이터 생성 (편집 중 keyringDataList -> 캡쳐용으로 변환)
        let captureKeyrings: [MultiKeyringCaptureScene.KeyringData] = keyringDataList.map { item in
            MultiKeyringCaptureScene.KeyringData(
                index: item.index,
                position: item.position,
                bodyImageURL: item.bodyImageURL,
                templateId: item.templateId ?? "",
                hookOffsetY: item.hookOffsetY,
                chainLength: item.chainLength,
                isGyroscope: item.isGyroscope
            )
        }

        // 카라비너 타입 및 이미지 URL
        let carabinerType = cb.type
        let carabinerBackURL: String?
        let carabinerFrontURL: String?
        if carabinerType == .hamburger {
            carabinerBackURL = cb.carabinerImage[1]
            carabinerFrontURL = cb.carabinerImage[2]
        } else {
            carabinerBackURL = cb.carabinerImage[0]
            carabinerFrontURL = nil
        }

        // 1. 배경 포함 캡쳐 (앱용)
        guard let fullImageData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: captureKeyrings,
            backgroundImageURL: bg.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerId: cb.id ?? "",
            carabinerX: cb.carabinerX,
            carabinerY: cb.carabinerY,
            carabinerWidth: cb.carabinerWidth
        ) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }

        // 2. 배경 없이 캡쳐 (위젯용 - 투명 여백 제거 후 리사이즈)
        let widgetImageData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: captureKeyrings,
            backgroundImageURL: nil,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerId: cb.id ?? "",
            carabinerX: cb.carabinerX,
            carabinerY: cb.carabinerY,
            carabinerWidth: cb.carabinerWidth,
            trimTransparentEdges: true
        )

        // 캐시 저장 (full + widget)
        BundleImageCache.shared.syncBundle(
            id: bundleId,
            name: bundleName,
            fullImageData: fullImageData,
            widgetImageData: widgetImageData,
            createdAt: createdAt
        )

        await MainActor.run {
            bundleVM.bundleCapturedImage = fullImageData
            isCapturing = false
        }
    }
}
