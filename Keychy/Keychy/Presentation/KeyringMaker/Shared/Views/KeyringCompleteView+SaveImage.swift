//
//  KeyringCompleteView+SaveImage.swift
//  Keychy
//
//  이미지 캡처 및 저장 기능
//

import SwiftUI
import Photos
import SpriteKit

// MARK: - Transparent Keyring Capture
extension KeyringCompleteView {
    /// 키링을 투명 배경 PNG로 캡처
    func captureKeyringToPNG() async -> UIImage? {
        guard let bodyImage = viewModel.bodyImage else {
            print("[KeyringCapture] bodyImage 없음")
            return nil
        }

        // 캡처용 Scene 생성 (투명 배경)
        let scene = KeyringCellScene(
            ringType: .basic,
            chainType: .basic,
            bodyUIImage: bodyImage,
            templateId: viewModel.templateId,
            isGyroscope: viewModel.isGyroscope,
            targetSize: CGSize(width: 350, height: 466),
            customBackgroundColor: .clear,
            zoomScale: 2.0,
            hookOffsetY: viewModel.hookOffsetY != 0 ? viewModel.hookOffsetY : nil,
            chainLength: viewModel.chainLength
        )
        scene.scaleMode = .aspectFill

        // 로딩 완료 대기용 플래그
        var loadingCompleted = false
        scene.onLoadingComplete = {
            loadingCompleted = true
        }

        // SKView 생성 및 Scene 표시
        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.presentScene(scene)

        // 로딩 완료 대기 (최대 3초)
        var waitTime = 0.0
        let checkInterval = 0.1
        let maxWaitTime = 3.0

        while !loadingCompleted && waitTime < maxWaitTime {
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
            waitTime += checkInterval
        }

        if !loadingCompleted {
            print("[KeyringCapture] 타임아웃 - 로딩 미완료")
        } else {
            // 로딩 완료 후 추가 렌더링 대기
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        // PNG 캡처
        guard let pngData = await scene.captureToPNG(),
              let image = UIImage(data: pngData) else {
            print("[KeyringCapture] PNG 캡처 실패")
            return nil
        }

        return image
    }
}

// MARK: - Photo Library Save
extension KeyringCompleteView {
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
    func saveImageToLibrary(_ image: UIImage) {
        requestPhotoLibraryPermission { granted in
            guard granted else {
                // TODO: 권한 거부 시 설정 유도 alert
                print("Photo library permission denied")
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { [self] success, error in
                DispatchQueue.main.async {
                    if success {
                        // 저장 성공 alert 표시
                        showImageSaved = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showImageSaved = false
                        }
                    }
                }
            }
        }
    }

    /// 이미지 캡처 및 저장 (메인 함수)
    func captureAndSaveImage() {
        // 캡처 중 표시
        withAnimation(.none) {
            isCapturingImage = true
        }

        Task {
            // 투명 배경 PNG 캡처
            guard let image = await captureKeyringToPNG() else {
                print("[KeyringCapture] 캡처 실패")
                await MainActor.run {
                    withAnimation(.none) {
                        isCapturingImage = false
                    }
                }
                return
            }

            // 이미지 저장
            await MainActor.run {
                saveImageToLibrary(image)
                withAnimation(.none) {
                    isCapturingImage = false
                }
            }
        }
    }
}
