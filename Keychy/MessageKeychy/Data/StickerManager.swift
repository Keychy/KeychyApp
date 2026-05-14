//
//  StickerManager.swift
//  MessageKeychy
//
//  Created by 길지훈 on 2026-04-22.
//

import Messages

/// App Group 공유 컨테이너에서 APNG 스티커를 MSSticker로 변환
///
/// `StickerDataManager`가 ID/파일 관리를 담당하고,
/// 이 매니저는 MSSticker 객체 생성만 담당한다.
enum StickerManager {

    private static let appGroupID = "group.keychy.app"

    /// size에 따라 StickerAPNG/ 또는 StickerAPNG_Big/ 디렉토리 반환
    private static func stickerDirectory(for size: StickerSize) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(size.directoryName, isDirectory: true)
    }

    /// 선택된 ID 순서대로 APNG 스티커를 MSSticker 배열로 로드
    ///
    /// - Parameters:
    ///   - ids: 캐러셀에 표시할 키링 ID 배열 (순서 유지)
    ///   - size: 로드할 스티커 크기 (.small: 탭 전송용, .big: 드래그 전송용)
    /// - Returns: (id, MSSticker) 튜플 배열. APNG 파일이 없는 ID는 스킵.
    static func loadStickers(for ids: [String], size: StickerSize = .small) -> [(id: String, sticker: MSSticker)] {
        guard let dir = stickerDirectory(for: size) else { return [] }

        return ids.compactMap { id in
            let url = dir.appendingPathComponent("\(id).png")
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return (try? MSSticker(contentsOfFileURL: url, localizedDescription: id))
                .map { (id, $0) }
        }
    }

}
