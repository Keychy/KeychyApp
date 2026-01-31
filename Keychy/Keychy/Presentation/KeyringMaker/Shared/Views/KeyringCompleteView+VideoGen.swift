//
//  KeyringCompleteView+VideoGen.swift
//  Keychy
//
//  Created by 길지훈 on 1/12/26.
//

import SwiftUI
import Photos

// MARK: - Video Generation

extension KeyringCompleteView {

    /// 영상 생성 및 사진 앨범에 저장
    func generateAndSaveVideo() async {
        isGeneratingVideo = true

        do {
            // 영상 생성
            let videoURL = try await videoGenerator.generateVideo(viewModel: viewModel)

            // 사진 앨범 저장
            try await saveVideoToPhotoLibrary(url: videoURL)

            // 성공 Alert 표시
            await MainActor.run {
                showVideoSaved = true
            }

            // 임시 파일 삭제
            try? FileManager.default.removeItem(at: videoURL)

        } catch {
            // TODO: 에러 처리 및 사용자 알림
        }

        isGeneratingVideo = false
    }

    /// 비디오 파일을 사진 라이브러리에 저장
    private func saveVideoToPhotoLibrary(url: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }

    // MARK: - Share

    /// 공유용 영상 생성 (캐싱)
    func generateVideoForShare() async {
        isGeneratingVideo = true

        do {
            let videoURL = try await videoGenerator.generateVideo(viewModel: viewModel)
            cachedVideoURL = videoURL
            showShareSheet = true
        } catch {
            print("[VideoShare] 영상 생성 실패: \(error)")
        }

        isGeneratingVideo = false
    }

    /// 캐시된 영상 파일 삭제
    func cleanupCachedVideo() {
        guard let url = cachedVideoURL else { return }
        try? FileManager.default.removeItem(at: url)
        cachedVideoURL = nil
    }
}

