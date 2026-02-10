//
//  BundleDetailView+SaveImage.swift
//  Keychy
//
//  Created by seo on 11/15/25.
//
// 뭉치 이미지 저장하는 로직을 담은 화면입니다.
import SwiftUI
import Photos

extension BundleDetailView {
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
            requestPhotoLibraryPermission { [self] granted in
                guard granted else {
                    Task { @MainActor in
                        uiState.isCapturing = false
                    }
                    continuation.resume()
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    Task { @MainActor in
                        if success {
                            print("[BundleDetailView] 이미지 저장 성공")
                        } else if let error = error {
                            print("[BundleDetailView] 이미지 저장 실패: \(error.localizedDescription)")
                        }
                        
                        // 캡처 상태 해제
                        uiState.isCapturing = false
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    func captureAndSaveScene() async {
        guard let bundle = bundleVM.selectedBundle else {
            return
        }
        
        // 캡쳐 시작
        await MainActor.run {
            uiState.isCapturing = true
        }
        
        // 배경 및 카라비너 로드
        guard let cb = bundleVM.resolveCarabiner(from: bundle.selectedCarabiner),
              let bg = WorkshopDataManager.shared.backgrounds.first(where: { $0.id == bundle.selectedBackground }) else {
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    uiState.isCapturing = false
                }
            }
            return
        }
        
        // 캡쳐용 키링 데이터 생성 - Firebase에서 키링 정보 가져오기
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []
        
        for (index, keyringId) in bundle.keyrings.enumerated() {
            // 유효하지 않은 키링 ID 필터링
            guard index < cb.maxKeyringCount,
                  keyringId != "none",
                  !keyringId.isEmpty else { 
                continue 
            }
            
            // Firebase에서 키링 정보 가져오기
            guard let keyringInfo = await bundleVM.fetchKeyringInfo(keyringId: keyringId) else {
                continue
            }
            
            keyringDataList.append(
                MultiKeyringCaptureScene.KeyringData(
                    index: index,
                    position: CGPoint(
                        x: cb.keyringXPosition[index],
                        y: cb.keyringYPosition[index]
                    ),
                    bodyImageURL: keyringInfo.bodyImage,
                    templateId: keyringInfo.selectedTemplate ?? "",
                    hookOffsetY: keyringInfo.hookOffsetY,
                    chainLength: keyringInfo.chainLength
                )
            )
        }
        
        let carabinerType = CarabinerType.from(cb.carabinerType)
        let carabinerBackURL: String?
        let carabinerFrontURL: String?
        
        if carabinerType == .hamburger {
            carabinerBackURL = cb.carabinerImage[1]
            carabinerFrontURL = cb.carabinerImage[2]
        } else {
            //plain 타입일 때
            carabinerBackURL = cb.carabinerImage[0]
            carabinerFrontURL = nil
        }
        
        // 1. 투명 배경으로 캡쳐 (앨범 저장용)
        guard let fullImageData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: nil,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerId: bundle.selectedCarabiner,
            carabinerX: cb.carabinerX,
            carabinerY: cb.carabinerY,
            carabinerWidth: cb.carabinerWidth
        ) else {
            await MainActor.run {
                uiState.isCapturing = false
            }
            return
        }

        // viewModel에 캡쳐된 이미지 저장
        await MainActor.run {
            bundleVM.bundleCapturedImage = fullImageData
        }

        // 캐시가 없는 경우에만 복구 (위젯용 포함)
        if let documentId = bundle.documentId,
           !BundleImageCache.shared.exists(for: documentId) {
            // 2. 배경 없이 캡쳐 (위젯용 - 투명 여백 제거 후 리사이즈)
            let widgetImageData = await MultiKeyringCaptureScene.captureBundleImage(
                keyringDataList: keyringDataList,
                backgroundImageURL: nil,
                carabinerBackImageURL: carabinerBackURL,
                carabinerFrontImageURL: carabinerFrontURL,
                carabinerType: carabinerType,
                carabinerId: bundle.selectedCarabiner,
                carabinerX: cb.carabinerX,
                carabinerY: cb.carabinerY,
                carabinerWidth: cb.carabinerWidth,
                trimTransparentEdges: true
            )

            BundleImageCache.shared.syncBundle(
                id: documentId,
                name: bundle.name,
                fullImageData: fullImageData,
                widgetImageData: widgetImageData,
                createdAt: bundle.createdAt
            )
            print("[BundleDetailView] 편집된 뭉치 캐시 복구: \(documentId)")
        }
        
        // PNG 데이터를 UIImage로 변환하여 포토 라이브러리에 저장
        guard let image = UIImage(data: fullImageData) else {
            await MainActor.run {
                uiState.isCapturing = false
            }
            return
        }
        
        await saveImageToLibrary(image)
    }
}
