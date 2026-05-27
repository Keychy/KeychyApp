//
//  StickerDataManager.swift
//  MessageKeychy
//
//  Created by 길지훈 on 2026-04-22.
//

import Foundation

/// App Group 공유 컨테이너에서 스티커 관련 데이터를 읽고 쓰는 매니저
///
/// - `sticker_keyrings.json`: 메인 앱이 작성한 전체 키링 메타데이터 (읽기 전용)
/// - `selected_stickers.json`: 캐러셀에 표시할 키링 ID 배열 (읽기/쓰기)
/// - `KeyringThumbnails/`: 메인 앱이 캐싱한 썸네일 PNG (읽기 전용)
enum StickerDataManager {

    private static let allKeyringsFileName = "sticker_keyrings.json"
    private static let selectedIDsFileName = "selected_stickers.json"
    private static let thumbnailDirName = "KeyringThumbnails"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)
    }

    // MARK: - 전체 키링 메타데이터

    /// 메인 앱이 저장한 전체 키링 목록 로드
    static func loadAllKeyrings() -> [StickerKeyring] {
        guard let url = containerURL?.appendingPathComponent(allKeyringsFileName),
              let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([StickerKeyring].self, from: data)) ?? []
    }

    // MARK: - 선택된 스티커 ID

    /// 캐러셀에 표시할 키링 ID 배열 로드
    static func loadSelectedIDs() -> [String] {
        guard let url = containerURL?.appendingPathComponent(selectedIDsFileName),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    /// 캐러셀에 표시할 키링 ID 배열 저장
    static func saveSelectedIDs(_ ids: [String]) {
        guard let url = containerURL?.appendingPathComponent(selectedIDsFileName) else { return }
        guard let data = try? JSONEncoder().encode(ids) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// 스티커 추가 (캐러셀 맨 앞에 삽입)
    static func addSticker(id: String) {
        var ids = loadSelectedIDs()
        guard !ids.contains(id) else { return }
        ids.insert(id, at: 0)
        saveSelectedIDs(ids)
    }

    /// 스티커 제거
    static func removeSticker(id: String) {
        var ids = loadSelectedIDs()
        ids.removeAll { $0 == id }
        saveSelectedIDs(ids)

        // APNG 파일도 삭제
        StickerGenerator.deleteSticker(for: id)
    }

    // MARK: - 오버사이즈 스티커 정리

    /// SMALL(StickerAPNG/) 디렉토리에서 500KB 초과 파일을 삭제하고 선택 목록에서 제거
    ///
    /// BIG(StickerAPNG_Big/)은 드래그 전송 전용으로 용량 제한이 없으므로 정리 대상에서 제외한다.
    /// 삭제된 스티커는 사용자가 피커에서 다시 추가하면 올바른 크기로 재생성된다.
    static func cleanOversizedStickers() {
        let selectedIDs = loadSelectedIDs()
        guard !selectedIDs.isEmpty else { return }

        guard let dir = containerURL?.appendingPathComponent("StickerAPNG", isDirectory: true) else { return }

        var validIDs = [String]()
        let maxBytes: Int64 = 500 * 1024

        for id in selectedIDs {
            let url = dir.appendingPathComponent("\(id).png")
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64,
               size <= maxBytes {
                validIDs.append(id)
            } else {
                // SMALL/BIG 둘 다 정리 — 이전엔 url(SMALL)만 지워서 BIG 고아 발생
                StickerGenerator.deleteSticker(for: id)
            }
        }

        if validIDs.count != selectedIDs.count {
            saveSelectedIDs(validIDs)
        }
    }

    // MARK: - 썸네일 경로

    /// 키링 썸네일 이미지 경로 반환
    static func thumbnailURL(for keyringID: String) -> URL? {
        containerURL?
            .appendingPathComponent(thumbnailDirName, isDirectory: true)
            .appendingPathComponent("\(keyringID)_thumb.png")
    }
}
