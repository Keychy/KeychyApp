//
//  StickerGenerator.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-22.
//

import UIKit

/// 스티커 크기 모드
///
/// MSSticker는 **탭 전송 시 500KB 제한**이 있지만,
/// **꾹 눌러 드래그(peel) 전송은 제한 없음**.
/// - `big`: 300px, 12프레임, 용량 제한 없음 (드래그 전송 전용)
/// - `small`: 200px, 12프레임, 450KB 이하 (탭 전송용)
enum StickerSize {
    case big
    case small

    var pixelSize: Int {
        switch self {
        case .big: return 500
        case .small: return 200
        }
    }

    var directoryName: String {
        switch self {
        case .big: return "StickerAPNG_Big"
        case .small: return "StickerAPNG"
        }
    }
}

/// StickerKeyring → APNG 스티커 변환 및 App Group 저장
///
/// ### 파이프라인
/// bodyImage 다운로드 → generateFrames(58장) → 12프레임 추출 → 화질 조절 → APNG 인코딩 → 크기 검증
///
/// ### SMALL (탭 전송): 500KB 제한 (MSSticker 필수)
/// Apple은 APNG/GIF 스티커를 **500KB 이하**로 강제한다.
/// 초과 시 MSSticker 객체는 생성되지만 탭 전송이 실패한다.
///
/// ### BIG (드래그 전송): 용량 제한 없음
/// 꾹 눌러 드래그(peel) 전송은 용량 제한이 없으므로 300px 고화질로 생성한다.
enum StickerGenerator {

    /// 58장 중 12장을 균등 간격으로 추출 (stride = 5)
    private static let frameCount = 12
    private static let frameStride = 5
    private static let frameDelay: Double = 0.1
    private static let maxFileSizeBytes = 450 * 1024  // SMALL 전용: 500KB 미만 안전 마진
    private static let appGroupID = "group.keychy.app"

    // MARK: - 경로

    private static func stickerDirectory(for size: StickerSize) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(size.directoryName, isDirectory: true)
    }

    static func stickerURL(for keyringID: String, size: StickerSize = .small) -> URL? {
        stickerDirectory(for: size)?.appendingPathComponent("\(keyringID).png")
    }

    // MARK: - 생성

    /// StickerKeyring → APNG 스티커 생성 및 App Group 저장
    ///
    /// - `small`: 200px, 450KB 이하 강제 (탭 전송용)
    /// - `big`: 300px, 용량 제한 없음 (드래그 전송용)
    static func generateSticker(for keyring: StickerKeyring, size: StickerSize) async -> URL? {
        let keyringID = keyring.id

        // 1. bodyImage 다운로드
        guard let bodyImage = await downloadBodyImage(urlString: keyring.bodyImageURL) else {
            print("[StickerGen] bodyImage 다운로드 실패: \(keyringID)")
            return nil
        }

        // 2. 프레임 합성 (58장)
        guard let rawFrames = KeyringFrameCompositor.generateFrames(
            from: bodyImage,
            chainLength: keyring.chainLength,
            template: keyring.selectedTemplate,
            isGyroscope: keyring.isGyroscope
        ) else {
            print("[StickerGen] 프레임 합성 실패: \(keyringID)")
            return nil
        }

        // 3. 58장 → 12장 균등 추출
        let selectedFrames = stride(from: 0, to: rawFrames.count, by: frameStride)
            .prefix(frameCount)
            .map { rawFrames[$0] }
        print("[StickerGen] 프레임 추출: \(rawFrames.count)장 → \(selectedFrames.count)장")

        // 4. 지정 크기로 다운샘플
        let pixelSize = size.pixelSize
        print("[StickerGen] [\(size)] \(pixelSize)px, \(selectedFrames.count)프레임 생성 시작")

        let processedImages = selectedFrames.compactMap { data -> UIImage? in
            downsample(pngData: data, to: pixelSize)
        }

        guard processedImages.count == selectedFrames.count else {
            print("[StickerGen] 프레임 처리 실패: \(processedImages.count)/\(selectedFrames.count)")
            return nil
        }

        // 5. APNG 인코딩
        guard let apngData = APNGEncoder.encode(
            frames: processedImages,
            delayTime: frameDelay,
            loopCount: 0
        ) else {
            print("[StickerGen] APNG 인코딩 실패")
            return nil
        }

        let sizeKB = apngData.count / 1024
        print("[StickerGen] 인코딩 결과: \(sizeKB)KB")

        // 6. SMALL만 크기 검증 (BIG은 용량 제한 없음)
        if size == .small && apngData.count > maxFileSizeBytes {
            print("[StickerGen] ❌ SMALL \(sizeKB)KB > 450KB 초과")
            return nil
        }

        // 7. 파일 저장
        guard let dir = stickerDirectory(for: size) else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("\(keyringID).png")

        do {
            try apngData.write(to: fileURL, options: .atomic)
            print("[StickerGen] ✅ [\(size)] 생성 완료: \(keyringID) (\(sizeKB)KB, \(pixelSize)px, \(selectedFrames.count)f)")
            return fileURL
        } catch {
            print("[StickerGen] 파일 저장 실패: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 삭제

    /// 특정 키링의 BIG/SMALL 스티커 모두 삭제
    static func deleteSticker(for keyringID: String) {
        for size in [StickerSize.small, .big] {
            guard let url = stickerURL(for: keyringID, size: size) else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Private

    private static func downloadBodyImage(urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("[StickerGen] 이미지 다운로드 에러: \(error.localizedDescription)")
            return nil
        }
    }

    private static func downsample(pngData: Data, to size: Int) -> UIImage? {
        guard let source = UIImage(data: pngData)?.cgImage else { return nil }
        guard let ctx = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))
        guard let cgImage = ctx.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
