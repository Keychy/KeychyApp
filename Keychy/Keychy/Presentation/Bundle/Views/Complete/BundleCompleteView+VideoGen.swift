//
//  BundleCompleteView+VideoGen.swift
//  Keychy
//
//  Created by 길지훈 on 2/7/26.
//
//  뭉치 완성뷰 - 영상 생성 기능

import SwiftUI
import Photos

// MARK: - Video Generation
extension BundleCompleteView {

    /// 공유용 영상 생성 (캐싱)
    @MainActor
    func generateVideoForShare() async {
        isGeneratingVideo = true

        do {
            guard let carabiner = bundleVM.selectedCarabiner,
                  let background = bundleVM.selectedBackground else {
                isGeneratingVideo = false
                return
            }

            // 배경 이미지 로드
            let backgroundImage = await loadImage(from: background.backgroundImage)

            // 영상 생성
            let videoURL = try await videoGenerator.generateVideo(
                keyringDataList: keyringDataList,
                backgroundImage: backgroundImage,
                backgroundImageURL: background.backgroundImage,
                backgroundLottieId: background.isLottie ? background.id : nil,
                carabinerBackImageURL: carabiner.backImageURL,
                carabinerFrontImageURL: carabiner.frontImageURL,
                carabinerLottieId: carabiner.isLottie ? carabiner.id : nil,
                carabinerX: carabiner.carabinerX,
                carabinerY: carabiner.carabinerY,
                carabinerWidth: carabiner.carabinerWidth,
                carabinerType: carabiner.type,
                bundleScale: 2.5
            )

            cachedVideoURL = videoURL
            isGeneratingVideo = false

            // UI 업데이트 완료 대기 후 시트 표시
            try? await Task.sleep(for: .seconds(0.3))
            showShareSheet = true

        } catch {
            print("[BundleCompleteView] 영상 생성 실패: \(error)")
            isGeneratingVideo = false
        }
    }

    /// 영상 생성 및 사진 앨범에 저장
    @MainActor
    func generateAndSaveVideo() async {
        isGeneratingVideo = true

        do {
            guard let carabiner = bundleVM.selectedCarabiner,
                  let background = bundleVM.selectedBackground else {
                isGeneratingVideo = false
                return
            }

            // 배경 이미지 로드
            let backgroundImage = await loadImage(from: background.backgroundImage)

            // 영상 생성
            let videoURL = try await videoGenerator.generateVideo(
                keyringDataList: keyringDataList,
                backgroundImage: backgroundImage,
                backgroundImageURL: background.backgroundImage,
                backgroundLottieId: background.isLottie ? background.id : nil,
                carabinerBackImageURL: carabiner.backImageURL,
                carabinerFrontImageURL: carabiner.frontImageURL,
                carabinerLottieId: carabiner.isLottie ? carabiner.id : nil,
                carabinerX: carabiner.carabinerX,
                carabinerY: carabiner.carabinerY,
                carabinerWidth: carabiner.carabinerWidth,
                carabinerType: carabiner.type,
                bundleScale: 2.5
            )

            // 사진 앨범 저장
            try await saveVideoToPhotoLibrary(url: videoURL)

            // 임시 파일 삭제
            try? FileManager.default.removeItem(at: videoURL)

            // 성공 Alert 표시
            isGeneratingVideo = false
            showVideoSaved = true

        } catch {
            print("[BundleCompleteView] 영상 생성 실패: \(error)")
            isGeneratingVideo = false
        }
    }

    /// 비디오 파일을 사진 라이브러리에 저장
    private func saveVideoToPhotoLibrary(url: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }

    /// URL에서 이미지 로드
    private func loadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("[BundleCompleteView] 배경 이미지 로드 실패: \(error)")
            return nil
        }
    }

    /// 캐시된 영상 파일 삭제
    func cleanupCachedVideo() {
        guard let url = cachedVideoURL else { return }
        try? FileManager.default.removeItem(at: url)
        cachedVideoURL = nil
    }
}
