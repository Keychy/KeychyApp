//
//  AnimationFrameStorage.swift
//  Keychy
//
//  Created by 길지훈 on 2025-03-05.
//

import Foundation
import UIKit

/// App Group에 키링별 애니메이션 프레임을 저장/로드하는 유틸리티
///
/// 디렉토리 구조:
/// ```
/// AppGroup/
///   AnimatedFrames/
///     {keyringID}/
///       frame_00.png … frame_57.png
/// ```
nonisolated enum AnimationFrameStorage {

    /// 편도 프레임 수 (디자이너 제공: 0→29)
    static let baseFrameCount = 30
    /// 왕복 포함 총 프레임 수 (0→29→28→...→1)
    static let totalFrameCount = baseFrameCount * 2 - 2
    private static let appGroupID = "group.keychy.app"
    private static let rootDirName = "AnimatedFrames"

    // MARK: - 경로

    /// AnimatedFrames 루트 디렉토리
    private static var rootDirectory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(rootDirName, isDirectory: true)
    }

    /// 특정 키링의 프레임 디렉토리
    private static func framesDirectory(for keyringID: String) -> URL? {
        rootDirectory?.appendingPathComponent(keyringID, isDirectory: true)
    }

    /// 특정 키링의 특정 프레임 URL
    static func frameURL(keyringID: String, index: Int) -> URL? {
        framesDirectory(for: keyringID)?.appendingPathComponent(
            String(format: "frame_%02d.png", index)
        )
    }

    // MARK: - 저장

    /// 왕복 프레임을 App Group에 저장
    ///
    /// 기존 프레임이 있으면 삭제 후 새로 저장한다.
    /// 위젯 프로세스의 파일 캐시 문제를 방지하기 위해
    /// in-place 덮어쓰기가 아닌 디렉토리 재생성 방식을 사용.
    static func saveFrames(_ pngDataArray: [Data], keyringID: String) throws {
        guard let dir = framesDirectory(for: keyringID) else {
            throw AnimationFrameStorageError.appGroupNotAvailable
        }

        let fm = FileManager.default

        // 기존 프레임 디렉토리 삭제 후 재생성
        if fm.fileExists(atPath: dir.path) {
            try fm.removeItem(at: dir)
        }
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)

        for (index, data) in pngDataArray.enumerated() {
            let url = dir.appendingPathComponent(
                String(format: "frame_%02d.png", index)
            )
            try data.write(to: url, options: .atomic)
        }
    }

    // MARK: - 조회

    /// 왕복 프레임이 모두 존재하는지 확인
    static func hasFrames(keyringID: String) -> Bool {
        guard let dir = framesDirectory(for: keyringID) else { return false }
        let fm = FileManager.default

        for i in 0..<totalFrameCount {
            let url = dir.appendingPathComponent(
                String(format: "frame_%02d.png", i)
            )
            guard fm.fileExists(atPath: url.path) else { return false }
        }
        return true
    }

    /// 왕복 프레임 UIImage 배열 로드 (위젯에서 사용)
    static func loadFrames(keyringID: String) -> [UIImage]? {
        guard let dir = framesDirectory(for: keyringID) else { return nil }

        var images = [UIImage]()
        images.reserveCapacity(totalFrameCount)

        for i in 0..<totalFrameCount {
            let url = dir.appendingPathComponent(
                String(format: "frame_%02d.png", i)
            )
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                return nil
            }
            images.append(image)
        }

        return images
    }

    // MARK: - 삭제

    /// 특정 키링의 프레임 삭제
    static func deleteFrames(keyringID: String) {
        guard let dir = framesDirectory(for: keyringID),
              FileManager.default.fileExists(atPath: dir.path) else { return }
        try? FileManager.default.removeItem(at: dir)
    }

    /// 전체 애니메이션 프레임 삭제
    static func deleteAllFrames() {
        guard let dir = rootDirectory,
              FileManager.default.fileExists(atPath: dir.path) else { return }
        try? FileManager.default.removeItem(at: dir)
    }
}

enum AnimationFrameStorageError: LocalizedError {
    case appGroupNotAvailable

    var errorDescription: String? {
        switch self {
        case .appGroupNotAvailable:
            "App Group 컨테이너에 접근할 수 없습니다"
        }
    }
}
