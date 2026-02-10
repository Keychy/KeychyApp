//
//  BundleCreateView+Capture.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI

// MARK: - 키링 데이터 및 캡처
extension BundleCreateView {
    /// 키링 데이터 리스트 생성 (씬 표시용)
    func createKeyringDataList(carabiner: Carabiner) -> [MultiKeyringScene.KeyringData] {
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

    /// 씬 캡처 및 저장
    func captureAndSaveScene() async {
        guard let cb = bundleVM.newSelectedCarabiner,
              let bg = bundleVM.newSelectedBackground else {
            return
        }

        let carabiner = cb.carabiner
        let background = bg.background

        // 캡처 시작
        await MainActor.run {
            isCapturing = true
            bundleVM.selectedKeyringsForBundle = selectedKeyrings
            bundleVM.selectedBackground = background
            bundleVM.selectedCarabiner = carabiner
        }

        // 배경 이미지 미리 로드
        guard let _ = try? await StorageManager.shared.getImage(path: background.backgroundImage) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }

        // 캡처용 키링 데이터 생성
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []

        for (index, keyring) in selectedKeyrings.sorted(by: { $0.key < $1.key }) {
            let data = MultiKeyringCaptureScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength
            )
            keyringDataList.append(data)
        }

        // 카라비너 이미지 추출
        let carabinerType = CarabinerType.from(carabiner.carabinerType)
        let carabinerBackURL: String?
        let carabinerFrontURL: String?

        if carabinerType == .hamburger {
            carabinerBackURL = carabiner.carabinerImage[1]
            carabinerFrontURL = carabiner.carabinerImage[2]
        } else {
            carabinerBackURL = carabiner.carabinerImage[0]
            carabinerFrontURL = nil
        }

        // 씬 캡처
        if let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: background.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerX: carabiner.carabinerX,
            carabinerY: carabiner.carabinerY,
            carabinerWidth: carabiner.carabinerWidth
        ) {
            await MainActor.run {
                bundleVM.bundleCapturedImage = pngData
            }
        }

        // 캡처 완료 후 다음 화면으로 이동
        await MainActor.run {
            isCapturing = false
            router.push(.bundleNameInputView)
        }
    }
}
