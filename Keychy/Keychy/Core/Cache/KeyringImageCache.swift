//
//  KeyringImageCache.swift
//  Keychy
//
//  Created by Rundo on 11/9/25.
//

import Foundation
import SwiftUI
import WidgetKit

/// Keyring 썸네일 이미지를 FileManager 기반으로 캐싱 (App Group 사용)
class KeyringImageCache {
    static let shared = KeyringImageCache()

    // MARK: - 이미지 타입 정의
    enum ImageType {
        case thumbnail  // 175*233 (보관함용)
        case gift       // 304*490 (선물/알림용)
        case widget     // 350*467 (위젯용 - 더 큼)

        var suffix: String {
            switch self {
            case .thumbnail: return "_thumb"
            case .gift: return "_gift"
            case .widget: return "_widget"
            }
        }

        var size: CGSize {
            switch self {
            case .thumbnail: return CGSize(width: 175, height: 233)
            case .gift: return CGSize(width: 304, height: 490)
            case .widget: return CGSize(width: 350, height: 467)
            }
        }
    }
    
    private let fileManager = FileManager.default
    private let appGroupIdentifier = "group.keychy.app"
    private let metadataFileName = "available_keyrings.json"
    private let widgetKind = "WidgetKeychy"

    /// App Group Container URL
    private var containerURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    /// 캐시 디렉토리 경로 (App Group)
    private var cacheDirectory: URL {
        guard let container = containerURL else {
            // Fallback to local cache if App Group is not available
            let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
            return urls[0].appendingPathComponent("KeyringThumbnails", isDirectory: true)
        }

        let keyringCache = container.appendingPathComponent("KeyringThumbnails", isDirectory: true)

        // 디렉토리가 없으면 생성
        if !fileManager.fileExists(atPath: keyringCache.path) {
            do {
                try fileManager.createDirectory(at: keyringCache, withIntermediateDirectories: true)
            } catch {
                print("[KeyringCache] 캐시 디렉토리 생성 실패: \(error.localizedDescription)")
            }
        }

        return keyringCache
    }

    /// 메타데이터 파일 URL
    private var metadataFileURL: URL? {
        containerURL?.appendingPathComponent(metadataFileName)
    }

    private init() {
        // 초기화
    }

    // MARK: - 저장

    /// PNG 데이터를 파일로 저장
    func save(pngData: Data, for keyringID: String, type: ImageType = .thumbnail) {
        let fileName = "\(keyringID)\(type.suffix).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        do {
            try pngData.write(to: fileURL)
        } catch {
            print("[KeyringCache] 저장 실패: \(keyringID) - \(error.localizedDescription)")
        }
    }

    // MARK: - 불러오기

    /// 캐시된 PNG 데이터 로드
    func load(for keyringID: String, type: ImageType = .thumbnail) -> Data? {
        let fileName = "\(keyringID)\(type.suffix).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            print("[KeyringCache] 로드 실패: \(keyringID) - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 삭제

    /// 특정 키링 캐시 삭제
    func delete(for keyringID: String, type: ImageType = .thumbnail) {
        let fileName = "\(keyringID)\(type.suffix).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("[KeyringCache] 삭제 실패: \(keyringID) - \(error.localizedDescription)")
        }
    }
    
    /// 특정 키링의 모든 타입 캐시 삭제
    func deleteAll(for keyringID: String) {
        delete(for: keyringID, type: .thumbnail)
        delete(for: keyringID, type: .gift)
        delete(for: keyringID, type: .widget)
    }

    // MARK: - 전체 캐시 삭제

    /// 모든 캐시 파일 및 메타데이터 삭제
    func clearAll() {
        // 1. 모든 이미지 캐시 삭제
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)

            for file in files where file.pathExtension == "png" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("[KeyringCache] 전체 캐시 삭제 실패: \(error.localizedDescription)")
        }

        // 2. 메타데이터 파일 삭제
        clearMetadata()

        // 3. 위젯 타임라인 새로고침
        reloadWidgets()
    }

    /// 메타데이터 파일 삭제
    func clearMetadata() {
        guard let fileURL = metadataFileURL else { return }

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("[KeyringCache] 메타데이터 삭제 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 캐시 존재 여부

    /// 캐시 파일이 존재하는지 확인 (조용히)
    func exists(for keyringID: String, type: ImageType = .thumbnail) -> Bool {
        let fileName = "\(keyringID)\(type.suffix).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - 캐시 정보

    /// 전체 캐시 파일 개수 및 용량 반환
    func getCacheInfo() -> (count: Int, totalSize: Int64) {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0

            for file in files where file.pathExtension == "png" {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }

            return (files.count, totalSize)
        } catch {
            print("[KeyringCache] 캐시 정보 조회 실패: \(error.localizedDescription)")
            return (0, 0)
        }
    }

    /// 모든 캐시 파일 목록 출력 (디버깅용)
    func printAllCachedFiles() {
        print("📋 [KeyringCache] ========== 캐시 파일 목록 ==========")
        print("📁 [KeyringCache] 경로: \(cacheDirectory.path)")

        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                .filter { $0.pathExtension == "png" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            if files.isEmpty {
                print("📭 [KeyringCache] 캐시 파일 없음")
                return
            }

            for (index, file) in files.enumerated() {
                let fileName = file.lastPathComponent
                let fileSize = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)

                print("📄 [KeyringCache] \(index + 1). \(fileName) - \(sizeString)")
            }

            let totalSize = files.reduce(Int64(0)) { sum, file in
                let size = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                return sum + size
            }
            let totalSizeString = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)

            print("📊 [KeyringCache] 총 \(files.count)개 파일, 총 용량 \(totalSizeString)")
        } catch {
            print("❌ [KeyringCache] 파일 목록 조회 실패: \(error.localizedDescription)")
        }

        print("📋 [KeyringCache] =====================================")
    }

    // MARK: - 위젯 메타데이터 관리

    /// 위젯용 키링 목록 저장
    func saveWidgetKeyrings(_ keyrings: [WidgetKeyring]) {
        guard let fileURL = metadataFileURL else {
            print("❌ [KeyringCache] 메타데이터 파일 URL을 찾을 수 없습니다.")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(keyrings)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ [KeyringCache] 메타데이터 저장 실패: \(error.localizedDescription)")
        }
    }

    /// 위젯용 키링 목록 로드
    func loadWidgetKeyrings() -> [WidgetKeyring] {
        guard let fileURL = metadataFileURL else {
            print("❌ [KeyringCache] 메타데이터 파일 URL을 찾을 수 없습니다.")
            return []
        }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("⚠️ [KeyringCache] 메타데이터 파일이 없습니다.")
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let keyrings = try decoder.decode([WidgetKeyring].self, from: data)
            return keyrings
        } catch {
            print("❌ [KeyringCache] 메타데이터 로드 실패: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 동기화 메서드

    /// 키링 추가 또는 업데이트 (이미지 + 메타데이터)
    func syncKeyring(id: String, name: String, imageData: Data, createdAt: Date) {
        // 1. 이미지 저장 (썸네일)
        save(pngData: imageData, for: id, type: .thumbnail)

        // 2. 위젯용 이미지 저장 (더 큰 사이즈)
        if let widgetData = resizeImageData(imageData, to: ImageType.widget.size) {
            save(pngData: widgetData, for: id, type: .widget)
        }

        // 3. 메타데이터 업데이트 (위젯용 이미지 경로 사용)
        var keyrings = loadWidgetKeyrings()
        let imagePath = "\(id)_widget.png"

        if let index = keyrings.firstIndex(where: { $0.id == id }) {
            // 기존 키링 업데이트
            keyrings[index] = WidgetKeyring(id: id, name: name, imagePath: imagePath, createdAt: createdAt)
        } else {
            // 새 키링 추가
            keyrings.append(WidgetKeyring(id: id, name: name, imagePath: imagePath, createdAt: createdAt))
        }

        saveWidgetKeyrings(keyrings)

        // 4. 위젯 타임라인 새로고침
        reloadWidgets()
    }

    /// 이미지 리사이즈
    private func resizeImageData(_ data: Data, to size: CGSize) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage?.pngData()
    }

    /// 키링 삭제 (이미지 + 메타데이터)
    func removeKeyring(id: String) {
        // 1. 이미지 삭제 (썸네일 + 위젯)
        delete(for: id, type: .thumbnail)
        delete(for: id, type: .widget)

        // 2. 메타데이터에서 제거
        var keyrings = loadWidgetKeyrings()
        keyrings.removeAll { $0.id == id }
        saveWidgetKeyrings(keyrings)

        print("✅ [KeyringCache] 키링 완전 삭제: \(id)")

        // 3. 위젯 타임라인 새로고침
        reloadWidgets()
    }

    /// 이미지 경로로 이미지 로드 (위젯용)
    func loadImageByPath(_ imagePath: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(imagePath)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            print("❌ [KeyringCache] 이미지 로드 실패: \(imagePath) - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 위젯 업데이트

    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    // MARK: - 마이그레이션

    private let migrationVersionKey = "widgetCacheMigrationVersion"
    private let currentMigrationVersion = 1

    /// 위젯 키링 데이터 마이그레이션 (한 번만 실행)
    /// - 삭제된 키링 정리
    /// - createdAt 누락된 키링 업데이트
    func migrateWidgetKeyringsIfNeeded(with keyringDates: [String: Date]) {
        let lastVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)
        guard lastVersion < currentMigrationVersion else { return }

        let originalKeyrings = loadWidgetKeyrings()

        let migratedKeyrings = originalKeyrings.compactMap { widgetKeyring -> WidgetKeyring? in
            guard let actualCreatedAt = keyringDates[widgetKeyring.id] else {
                delete(for: widgetKeyring.id, type: .thumbnail)
                return nil
            }

            if widgetKeyring.createdAt == .distantPast {
                return WidgetKeyring(
                    id: widgetKeyring.id,
                    name: widgetKeyring.name,
                    imagePath: widgetKeyring.imagePath,
                    createdAt: actualCreatedAt
                )
            }

            return widgetKeyring
        }

        if migratedKeyrings != originalKeyrings {
            saveWidgetKeyrings(migratedKeyrings)
            reloadWidgets()
        }

        UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
    }

    // MARK: - 캐시 스케일 버전 관리

    /// 캐시 스케일 버전 (KeyringScale 적용으로 인해 증가)
    /// - v1: 기존 하드코딩 210x210
    /// - v2: KeyringScale 템플릿별 maxSize 적용
    private let currentScaleVersion = 2
    private let scaleVersionKey = "keyringCacheScaleVersion"

    /// 캐시 스케일 버전이 변경되었으면 전체 캐시 삭제
    /// - 앱 시작 시 호출
    /// - 새 KeyringScale 로직으로 재캡처 유도
    func invalidateCacheIfScaleVersionChanged() {
        let savedVersion = UserDefaults.standard.integer(forKey: scaleVersionKey)

        guard savedVersion < currentScaleVersion else { return }

        print("[KeyringCache] 스케일 버전 변경 감지: v\(savedVersion) → v\(currentScaleVersion)")
        print("[KeyringCache] 캐시 전체 삭제 후 재캡처 예정")

        clearAll()

        UserDefaults.standard.set(currentScaleVersion, forKey: scaleVersionKey)
    }
}
