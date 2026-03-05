//
//  AnimationFrameStorage.swift
//  Keychy
//
//  Created by 길지훈 on 2025-03-05.
//

import Foundation
import UIKit

/// App Group에 키링별 애니메이션 프레임(30장 PNG)을 저장/로드하는 유틸리티
///
/// 앱에서 FrameCompositor로 합성한 30장 PNG를 저장하고,
/// 위젯에서 BlinkMask 애니메이션용으로 로드한다.
///
/// 디렉토리 구조:
/// ```
/// AppGroup/
///   AnimatedFrames/
///     {keyringID}/
///       frame_00.png … frame_29.png
/// ```
nonisolated enum AnimationFrameStorage {

    static let frameCount = 30
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

    /// 30장 PNG 프레임을 App Group에 저장
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

    /// 30장 프레임이 모두 존재하는지 확인
    static func hasFrames(keyringID: String) -> Bool {
        guard let dir = framesDirectory(for: keyringID) else { return false }
        let fm = FileManager.default

        for i in 0..<frameCount {
            let url = dir.appendingPathComponent(
                String(format: "frame_%02d.png", i)
            )
            guard fm.fileExists(atPath: url.path) else { return false }
        }
        return true
    }

    /// 30장 프레임 UIImage 배열 로드 (위젯에서 사용)
    static func loadFrames(keyringID: String) -> [UIImage]? {
        guard let dir = framesDirectory(for: keyringID) else { return nil }

        var images = [UIImage]()
        images.reserveCapacity(frameCount)

        for i in 0..<frameCount {
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
