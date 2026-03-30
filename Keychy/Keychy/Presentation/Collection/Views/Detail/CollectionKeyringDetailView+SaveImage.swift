//
//  CollectionKeyringDetailView+SaveImage.swift
//  Keychy
//
//  이미지 캡처 및 저장 기능
//

import SwiftUI
import Photos
import SpriteKit

// MARK: - Transparent Keyring Capture
extension CollectionKeyringDetailView {
    /// 키링을 투명 배경 PNG로 캡처
    func captureKeyringToPNG() async -> UIImage? {
        // 캡처용 Scene 생성 (투명 배경)
        let scene = KeyringCellScene(
            ringType: RingType.fromID(keyring.selectedRing),
            chainType: ChainType.fromID(keyring.selectedChain),
            bodyImage: keyring.bodyImage,
            templateId: keyring.selectedTemplate,
            isGyroscope: keyring.isGyroscope,
            targetSize: CGSize(width: 350, height: 466),
            customBackgroundColor: UIColor.clear,
            zoomScale: 2.0,
            hookOffsetY: keyring.hookOffsetY,
            chainLength: keyring.chainLength
        )
        scene.scaleMode = .aspectFill

        var loadingCompleted = false
        scene.onLoadingComplete = {
            loadingCompleted = true
        }

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

        if loadingCompleted {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        guard let pngData = await scene.captureToPNG(),
              let image = UIImage(data: pngData) else {
            return nil
        }

        return image
    }
}

// MARK: - Photo Library Save
extension CollectionKeyringDetailView {
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
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { [self] success, error in
                DispatchQueue.main.async {
                    if success {
                        // 저장 성공 애니메이션
                        showImageSaved = true
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                            checkmarkScale = 1.0
                            checkmarkOpacity = 1.0

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                                    checkmarkScale = 0.0
                                    checkmarkOpacity = 0.0
                                    showImageSaved = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// 이미지 캡처 및 저장 (메인 함수)
    func captureAndSaveImage() {
        Task {
            guard let image = await captureKeyringToPNG() else {
                print("[ImageCapture] 캡처 실패")
                return
            }
            await MainActor.run {
                saveImageToLibrary(image)
            }
        }
    }
}
