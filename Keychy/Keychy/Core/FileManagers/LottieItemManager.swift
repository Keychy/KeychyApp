//
//  LottieItemManager.swift
//  Keychy
//
//  Created by 길지훈 on 2/11/26.
//

import Foundation
import FirebaseStorage
import Lottie

/// 배경/카라비너 Lottie 에셋 다운로드 및 캐싱 매니저
/// - EffectManager와 동일한 다운로드/캐싱 패턴이지만, 배경/카라비너 도메인 전용
@MainActor
@Observable
class LottieItemManager {
    static let shared = LottieItemManager()

    var downloadProgress: [String: Double] = [:]
    var downloadingItemIds: Set<String> = []

    private init() {}

    // MARK: - 캐시 디렉토리 구분

    private enum AssetType: String {
        case background = "lottie_backgrounds"
        case carabinerBack = "lottie_carabiners_back"
        case carabinerFront = "lottie_carabiners_front"
    }

    // MARK: - 캐시 확인

    /// 배경 Lottie가 캐시에 있는지 확인
    func isBackgroundCached(id: String) -> Bool {
        return fileExists(id: id, type: .background)
    }

    /// 카라비너 뒷면 Lottie가 캐시에 있는지 확인
    func isCarabinerBackCached(id: String) -> Bool {
        return fileExists(id: id, type: .carabinerBack)
    }

    /// 카라비너 앞면 Lottie가 캐시에 있는지 확인
    func isCarabinerFrontCached(id: String) -> Bool {
        return fileExists(id: id, type: .carabinerFront)
    }

    // MARK: - 다운로드

    /// 배경 Lottie 다운로드
    func downloadBackgroundLottie(_ background: Background) async {
        guard let bgId = background.id,
              let lottieURL = background.backgroundLottie,
              !lottieURL.isEmpty else { return }

        await downloadLottie(
            id: bgId,
            remoteURL: lottieURL,
            type: .background
        )
    }

    /// 카라비너 Lottie 다운로드 (뒷면 + 앞면 병렬)
    func downloadCarabinerLottie(_ carabiner: Carabiner) async {
        guard let carabinerId = carabiner.id, carabiner.isLottie else { return }

        // 뒷면/앞면 병렬 다운로드
        async let backDownload: Void = {
            if let backURL = carabiner.backLottieURL {
                await self.downloadLottie(
                    id: carabinerId,
                    remoteURL: backURL,
                    type: .carabinerBack
                )
            }
        }()

        async let frontDownload: Void = {
            if let frontURL = carabiner.frontLottieURL {
                await self.downloadLottie(
                    id: carabinerId,
                    remoteURL: frontURL,
                    type: .carabinerFront
                )
            }
        }()

        await backDownload
        await frontDownload
    }

    // MARK: - Lottie 로드

    /// 배경 Lottie 애니메이션 로드
    func loadBackgroundAnimation(id: String) -> LottieAnimation? {
        return loadAnimation(id: id, type: .background)
    }

    /// 카라비너 뒷면 Lottie 애니메이션 로드
    func loadCarabinerBackAnimation(id: String) -> LottieAnimation? {
        return loadAnimation(id: id, type: .carabinerBack)
    }

    /// 카라비너 앞면 Lottie 애니메이션 로드
    func loadCarabinerFrontAnimation(id: String) -> LottieAnimation? {
        return loadAnimation(id: id, type: .carabinerFront)
    }

    // MARK: - Private

    /// 공통 다운로드 로직
    private func downloadLottie(id: String, remoteURL: String, type: AssetType) async {
        let downloadKey = "\(type.rawValue)_\(id)"

        // 이미 다운로드 중이면 무시
        guard !downloadingItemIds.contains(downloadKey) else { return }

        // 캐시 유효성 검증: 파일 존재 + URL 일치하면 스킵
        if fileExists(id: id, type: type) && isCacheValid(id: id, currentURL: remoteURL, type: type) {
            return
        }

        downloadingItemIds.insert(downloadKey)
        downloadProgress[downloadKey] = 0.0

        let storageRef = Storage.storage().reference(forURL: remoteURL)
        let localURL = cacheFileURL(id: id, type: type)

        // 디렉토리 생성
        let directory = localURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // 다운로드 실행
        let downloadTask = storageRef.write(toFile: localURL)

        // 진행률 관찰
        _ = downloadTask.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress,
                  progress.totalUnitCount > 0 else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            guard percentComplete.isFinite else { return }

            Task { @MainActor in
                self?.downloadProgress[downloadKey] = percentComplete
            }
        }

        // 완료 대기
        await withCheckedContinuation { continuation in
            downloadTask.observe(.success) { _ in
                continuation.resume()
            }
            downloadTask.observe(.failure) { _ in
                continuation.resume()
            }
        }

        // 파일 쓰기 완료 확인
        try? await Task.sleep(nanoseconds: 100_000_000)
        var attempts = 0
        while !FileManager.default.fileExists(atPath: localURL.path) && attempts < 5 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }

        // 캐시 URL 저장 (다음 검증용)
        saveCacheURL(id: id, url: remoteURL, type: type)

        // Lottie 애니메이션 캐시 클리어 (새 파일 로드를 위해)
        LottieAnimationCache.shared?.clearCache()

        downloadingItemIds.remove(downloadKey)
        downloadProgress.removeValue(forKey: downloadKey)
    }

    /// 캐시 파일 경로 생성
    private func cacheFileURL(id: String, type: AssetType) -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDirectory.appendingPathComponent("\(type.rawValue)/\(id).json")
    }

    /// 파일 존재 여부 확인
    private func fileExists(id: String, type: AssetType) -> Bool {
        let url = cacheFileURL(id: id, type: type)
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// 캐시에서 Lottie 애니메이션 로드
    private func loadAnimation(id: String, type: AssetType) -> LottieAnimation? {
        let url = cacheFileURL(id: id, type: type)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return LottieAnimation.filepath(url.path)
    }

    // MARK: - Cache Validation (UserDefaults 기반)

    private func cacheURLKey(for id: String, type: AssetType) -> String {
        return "cachedLottieURL_\(type.rawValue)_\(id)"
    }

    private func isCacheValid(id: String, currentURL: String, type: AssetType) -> Bool {
        let key = cacheURLKey(for: id, type: type)
        guard let savedURL = UserDefaults.standard.string(forKey: key) else { return false }
        return savedURL == currentURL
    }

    private func saveCacheURL(id: String, url: String, type: AssetType) {
        let key = cacheURLKey(for: id, type: type)
        UserDefaults.standard.set(url, forKey: key)
    }
}
