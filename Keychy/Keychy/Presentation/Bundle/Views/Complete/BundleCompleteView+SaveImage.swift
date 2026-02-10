//
//  BundleCompleteView+SaveImage.swift
//  Keychy
//
//  Created by 길지훈 on 2/7/26.
//
//  뭉치 완성뷰 - 이미지 캡처 및 저장 기능

import SwiftUI
import Photos

// MARK: - Photo Library Save
extension BundleCompleteView {

    /// 포토 라이브러리 권한 요청
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    /// 이미지를 포토 라이브러리에 저장
    @MainActor
    func saveImageToLibrary(_ image: UIImage) async {
        await withCheckedContinuation { continuation in
            requestPhotoLibraryPermission { granted in
                guard granted else {
                    Task { @MainActor in
                        isCapturing = false
                    }
                    continuation.resume()
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    Task { @MainActor in
                        if success {
                            print("[BundleCompleteView] 이미지 저장 성공")
                            showImageSaved = true
                        } else if let error = error {
                            print("[BundleCompleteView] 이미지 저장 실패: \(error.localizedDescription)")
                        }

                        // 캡처 상태 해제
                        isCapturing = false
                    }
                    continuation.resume()
                }
            }
        }
    }

    /// 이미지 캡처 및 저장 (메인 함수) - 로컬 데이터 사용
    func captureAndSaveImage() {
        guard let carabiner = bundleVM.selectedCarabiner,
              let background = bundleVM.selectedBackground else { return }

        // 캡쳐 시작
        withAnimation(.none) {
            isCapturing = true
        }

        Task {
            // 캡쳐용 키링 데이터 생성 (로컬 데이터 사용)
            var captureKeyringDataList: [MultiKeyringCaptureScene.KeyringData] = []
            let selectedKeyrings = bundleVM.selectedKeyringsForBundle

            for (index, keyring) in selectedKeyrings.sorted(by: { $0.key < $1.key }) {
                guard index < carabiner.maxKeyringCount else { continue }

                captureKeyringDataList.append(
                    MultiKeyringCaptureScene.KeyringData(
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
                )
            }

            let carabinerType = CarabinerType.from(carabiner.carabinerType)
            let carabinerBackURL: String?
            let carabinerFrontURL: String?

            if carabinerType == .hamburger {
                carabinerBackURL = carabiner.carabinerImage[1]
                carabinerFrontURL = carabiner.carabinerImage[2]
            } else {
                // plain 타입일 때
                carabinerBackURL = carabiner.carabinerImage[0]
                carabinerFrontURL = nil
            }

            // 투명 배경으로 캡쳐
            guard let fullImageData = await MultiKeyringCaptureScene.captureBundleImage(
                keyringDataList: captureKeyringDataList,
                backgroundImageURL: nil,
                carabinerBackImageURL: carabinerBackURL,
                carabinerFrontImageURL: carabinerFrontURL,
                carabinerType: carabinerType,
                carabinerId: carabiner.id ?? "",
                carabinerX: carabiner.carabinerX,
                carabinerY: carabiner.carabinerY,
                carabinerWidth: carabiner.carabinerWidth
            ) else {
                await MainActor.run {
                    isCapturing = false
                }
                return
            }

            // viewModel에 캡쳐된 이미지 저장
            await MainActor.run {
                bundleVM.bundleCapturedImage = fullImageData
            }

            // PNG 데이터를 UIImage로 변환하여 포토 라이브러리에 저장
            guard let image = UIImage(data: fullImageData) else {
                await MainActor.run {
                    isCapturing = false
                }
                return
            }

            await saveImageToLibrary(image)
        }
    }
}
