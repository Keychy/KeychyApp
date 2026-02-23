//
//  CollectionKeyringDetailView+VideoGen.swift
//  Keychy
//
//  Created by 길지훈 on 1/15/26.
//

import SwiftUI
import Photos

extension CollectionKeyringDetailView {
    /// 영상 생성 및 저장
    func generateAndSaveVideo() async {
        guard !isGeneratingVideo else { return }

        await MainActor.run {
            isGeneratingVideo = true
        }

        do {
            // 영상 생성
            let videoURL = try await videoGenerator.generateVideo(
                keyring: keyring,
                backgroundImage: UIImage(resource: .whiteBackground)
            )

            // 포토 라이브러리에 저장
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }

            // 임시 파일 삭제
            try? FileManager.default.removeItem(at: videoURL)

            // 완료 처리
            await MainActor.run {
                isGeneratingVideo = false
                showVideoSaved = true
            }

        } catch {
            print("[CollectionKeyringDetailView] 영상 생성 실패: \(error)")
            await MainActor.run {
                isGeneratingVideo = false
            }
        }
    }

    // MARK: - Share

    /// 공유용 영상 생성 (캐싱)
    func generateVideoForShare() async {
        guard !isGeneratingVideo else { return }

        await MainActor.run {
            isGeneratingVideo = true
        }

        do {
            let videoURL = try await videoGenerator.generateVideo(
                keyring: keyring,
                backgroundImage: UIImage(resource: .whiteBackground)
            )
            await MainActor.run {
                cachedVideoURL = videoURL
                isGeneratingVideo = false
            }
            // 블러 애니메이션 완료 후 공유 시트 표시
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run {
                showShareSheet = true
            }
        } catch {
            print("[CollectionKeyringDetailView] 영상 생성 실패: \(error)")
            await MainActor.run {
                isGeneratingVideo = false
            }
        }
    }

    /// 캐시된 영상 파일 삭제
    func cleanupCachedVideo() {
        guard let url = cachedVideoURL else { return }
        try? FileManager.default.removeItem(at: url)
        cachedVideoURL = nil
    }
}
