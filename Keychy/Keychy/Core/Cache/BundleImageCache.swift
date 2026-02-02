//
//  BundleImageCache.swift
//  Keychy
//
//  Created by Rundo on 11/10/25.
//

import Foundation
import SwiftUI
import WidgetKit

/// 번들(MultiKeyring) 썸네일 이미지를 FileManager 기반으로 캐싱 (App Group 사용)
class BundleImageCache {
    static let shared = BundleImageCache()

    // MARK: - 이미지 타입 정의
    enum ImageType {
        case full      // 배경 포함 (앱용)
        case widget    // 배경 없음 (위젯용)

        var suffix: String {
            switch self {
            case .full: return ""
            case .widget: return "_widget"
            }
        }
    }

    private let fileManager = FileManager.default
    private let appGroupIdentifier = "group.keychy.app"
    private let metadataFileName = "available_bundles.json"
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
            return urls[0].appendingPathComponent("BundleThumbnails", isDirectory: true)
        }

        let bundleCache = container.appendingPathComponent("BundleThumbnails", isDirectory: true)

        // 디렉토리가 없으면 생성
        if !fileManager.fileExists(atPath: bundleCache.path) {
            do {
                try fileManager.createDirectory(at: bundleCache, withIntermediateDirectories: true)
            } catch {
                print("❌ [BundleCache] 캐시 디렉토리 생성 실패: \(error.localizedDescription)")
            }
        }

        return bundleCache
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
    func save(pngData: Data, for bundleID: String, type: ImageType = .full) {
        let fileName = "\(bundleID)\(type.suffix).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        do {
            try pngData.write(to: fileURL)

        } catch {
            print("❌ [BundleCache] 저장 실패: \(bundleID) - \(error.localizedDescription)")
        }
    }

    // MARK: - 불러오기

    /// 캐시된 PNG 데이터 로드
    func load(for bundleID: String, type: ImageType = .full) -> Data? {
        let fileName = "\(bundleID)\(type.suffix).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            print("❌ [BundleCache] 로드 실패: \(bundleID) - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 삭제

    /// 특정 번들 캐시 삭제
    func delete(for bundleID: String, type: ImageType = .full) {
        let fileName = "\(bundleID)\(type.suffix).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("❌ [BundleCache] 삭제 실패: \(bundleID) - \(error.localizedDescription)")
        }
    }

    /// 특정 번들의 모든 타입 캐시 삭제
    func deleteAll(for bundleID: String) {
        delete(for: bundleID, type: .full)
        delete(for: bundleID, type: .widget)
    }

    // MARK: - 전체 캐시 삭제

    /// 모든 캐시 파일 삭제
    func clearAll() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)

            for file in files where file.pathExtension == "png" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("❌ [BundleCache] 전체 캐시 삭제 실패: \(error.localizedDescription)")
        }

        // 메타데이터 파일 삭제
        clearMetadata()

        // 위젯 타임라인 새로고침
        reloadWidgets()
    }

    /// 메타데이터 파일 삭제
    func clearMetadata() {
        guard let fileURL = metadataFileURL else { return }

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("❌ [BundleCache] 메타데이터 삭제 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 캐시 존재 여부

    /// 캐시 파일이 존재하는지 확인
    func exists(for bundleID: String, type: ImageType = .full) -> Bool {
        let fileName = "\(bundleID)\(type.suffix).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - 위젯 메타데이터 관리

    /// 위젯용 뭉치 목록 저장
    func saveWidgetBundleModels(_ bundles: [WidgetBundleModel]) {
        guard let fileURL = metadataFileURL else {
            print("❌ [BundleCache] 메타데이터 파일 URL을 찾을 수 없습니다.")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(bundles)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ [BundleCache] 메타데이터 저장 실패: \(error.localizedDescription)")
        }
    }

    /// 위젯용 뭉치 목록 로드
    func loadWidgetBundleModels() -> [WidgetBundleModel] {
        guard let fileURL = metadataFileURL else {
            print("❌ [BundleCache] 메타데이터 파일 URL을 찾을 수 없습니다.")
            return []
        }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let bundles = try decoder.decode([WidgetBundleModel].self, from: data)
            return bundles
        } catch {
            print("❌ [BundleCache] 메타데이터 로드 실패: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 동기화 메서드

    /// 뭉치 추가 또는 업데이트 (이미지 + 메타데이터)
    /// - Parameters:
    ///   - id: 뭉치 ID
    ///   - name: 뭉치 이름
    ///   - fullImageData: 배경 포함 이미지 (앱용)
    ///   - widgetImageData: 배경 없는 이미지 (위젯용, optional)
    ///   - createdAt: 생성일
    func syncBundle(id: String, name: String, fullImageData: Data, widgetImageData: Data? = nil, createdAt: Date = Date()) {
        // 1. 이미지 저장
        save(pngData: fullImageData, for: id, type: .full)

        // 위젯용 이미지가 있으면 저장
        if let widgetData = widgetImageData {
            save(pngData: widgetData, for: id, type: .widget)
        }

        // 2. 메타데이터 업데이트
        var bundles = loadWidgetBundleModels()
        // 위젯용 이미지가 있으면 _widget.png, 없으면 .png 사용
        let imagePath = widgetImageData != nil ? "\(id)_widget.png" : "\(id).png"

        if let index = bundles.firstIndex(where: { $0.id == id }) {
            // 기존 뭉치 업데이트
            bundles[index] = WidgetBundleModel(id: id, name: name, imagePath: imagePath, createdAt: createdAt)
        } else {
            // 새 뭉치 추가
            bundles.append(WidgetBundleModel(id: id, name: name, imagePath: imagePath, createdAt: createdAt))
        }

        saveWidgetBundleModels(bundles)

        // 3. 위젯 타임라인 새로고침
        reloadWidgets()
    }

    /// 뭉치 삭제 (이미지 + 메타데이터)
    func removeBundle(id: String) {
        // 1. 이미지 삭제 (full + widget 모두)
        deleteAll(for: id)

        // 2. 메타데이터에서 제거
        var bundles = loadWidgetBundleModels()
        bundles.removeAll { $0.id == id }
        saveWidgetBundleModels(bundles)

        print("✅ [BundleCache] 뭉치 완전 삭제: \(id)")

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
            print("❌ [BundleCache] 이미지 로드 실패: \(imagePath) - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 위젯 업데이트

    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
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
            print("❌ [BundleCache] 캐시 정보 조회 실패: \(error.localizedDescription)")
            return (0, 0)
        }
    }

    /// 모든 캐시 파일 목록 출력 (디버깅용)
    func printAllCachedFiles() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                .filter { $0.pathExtension == "png" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            if files.isEmpty {
                return
            }

            for (_, file) in files.enumerated() {
                _ = file.lastPathComponent
                let fileSize = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                _ = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)

            }

            let totalSize = files.reduce(Int64(0)) { sum, file in
                let size = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                return sum + size
            }
            _ = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)

        } catch {
            print("❌ [BundleCache] 파일 목록 조회 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 하위 호환성 (기존 AvailableBundle 지원)

    /// 기존 saveAvailableBundles 호환 (deprecated)
    @available(*, deprecated, message: "Use syncBundle(id:name:fullImageData:widgetImageData:createdAt:) instead")
    func saveAvailableBundles(_ bundles: [AvailableBundle]) {
        // AvailableBundle -> WidgetBundleModel 변환
        let widgetBundles = bundles.map {
            WidgetBundleModel(id: $0.id, name: $0.name, imagePath: $0.imagePath, createdAt: .distantPast)
        }
        saveWidgetBundleModels(widgetBundles)
    }

    /// 기존 loadAvailableBundles 호환 (deprecated)
    @available(*, deprecated, message: "Use loadWidgetBundleModels() instead")
    func loadAvailableBundles() -> [AvailableBundle] {
        let widgetBundles = loadWidgetBundleModels()
        return widgetBundles.map {
            AvailableBundle(id: $0.id, name: $0.name, imagePath: $0.imagePath)
        }
    }
}

/// 기존 번들 메타데이터 구조체 (하위 호환용)
struct AvailableBundle: Codable, Identifiable, Hashable {
    let id: String          // Firestore documentId
    let name: String        // 번들 이름
    let imagePath: String   // App Group 내 이미지 경로
}
