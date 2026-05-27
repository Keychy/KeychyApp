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
/// - `big`: 250px, 12프레임, 용량 제한 없음 (드래그 전송 전용)
/// - `small`: 200px, 12프레임, 450KB 이하 (탭 전송용)
enum StickerSize {
    case big
    case small

    var pixelSize: Int {
        switch self {
        // BIG은 500→350→250으로 점진 축소: 드롭 영역이 좁아져 화면 끝/
        // 메시지 옆에서도 iMessage가 reject하지 않고 잘 붙음
        // (Apple drop validation이 pixelSize도 참조한다고 가정한 실험적 값)
        case .big: return 250
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
/// 꾹 눌러 드래그(peel) 전송은 용량 제한이 없지만,
/// 드롭 영역이 너무 크면 iMessage가 화면 밖 침범으로 reject하므로 250px로 둠.
enum StickerGenerator {

    /// 58장 중 12장을 균등 간격으로 추출 (stride = 5)
    private static let frameCount = 12
    private static let frameStride = 5
    private static let frameDelay: Double = 0.1
    private static let maxFileSizeBytes = 450 * 1024  // SMALL 전용: 500KB 미만 안전 마진

    // MARK: - 경로

    private static func stickerDirectory(for size: StickerSize) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)?
            .appendingPathComponent(size.directoryName, isDirectory: true)
    }

    static func stickerURL(for keyringID: String, size: StickerSize = .small) -> URL? {
        stickerDirectory(for: size)?.appendingPathComponent("\(keyringID).png")
    }

    // MARK: - 생성

    /// 여러 사이즈의 스티커를 한 번에 생성
    ///
    /// 다운로드 + 프레임 합성(SpriteKit, 58장)은 사이즈와 무관하므로 1회만 수행한다.
    /// 사이즈별로 다른 건 다운샘플 해상도와 APNG 인코딩/검증/저장뿐.
    ///
    /// - Returns: 성공한 사이즈의 파일 URL 딕셔너리. 다운로드/프레임 합성 실패 시 빈 딕셔너리.
    static func generateStickers(for keyring: StickerKeyring, sizes: [StickerSize]) async -> [StickerSize: URL] {
        // 1. bodyImage 다운로드 (1회 공유)
        guard let bodyImage = await downloadBodyImage(urlString: keyring.bodyImageURL) else {
            return [:]
        }

        // 2. 프레임 합성 58장 (1회 공유) — 가장 무거운 작업
        guard let rawFrames = KeyringFrameCompositor.generateFrames(
            from: bodyImage,
            chainLength: keyring.chainLength,
            template: keyring.selectedTemplate,
            isGyroscope: keyring.isGyroscope
        ) else {
            return [:]
        }

        // 3. 12장 균등 추출 (1회 공유)
        let selectedFrames = stride(from: 0, to: rawFrames.count, by: frameStride)
            .prefix(frameCount)
            .map { rawFrames[$0] }

        // 4. 사이즈별 인코딩/저장 (개별)
        var results: [StickerSize: URL] = [:]
        for size in sizes {
            if let url = encodeAndSave(frames: selectedFrames, keyringID: keyring.id, size: size) {
                results[size] = url
            }
        }
        return results
    }

    /// 단일 사이즈 생성 (내부적으로 batch API 사용)
    static func generateSticker(for keyring: StickerKeyring, size: StickerSize) async -> URL? {
        await generateStickers(for: keyring, sizes: [size])[size]
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

    /// 12프레임 PNG Data → 다운샘플 → 투명 여백 트림 → APNG → 파일 저장
    private static func encodeAndSave(frames: [Data], keyringID: String, size: StickerSize) -> URL? {
        let pixelSize = size.pixelSize
        let processedImages = frames.compactMap { downsample(pngData: $0, to: pixelSize) }
        guard processedImages.count == frames.count else { return nil }

        // 캔버스 = 시각적 키링 영역이 되도록 12프레임의 union bbox로 trim
        // MSStickerView의 peel anchor가 캔버스 기준이라, 투명 여백이 있으면
        // 사용자가 잡은 위치와 실제 비주얼 위치가 어긋남
        let trimmedImages = trimTransparentEdges(processedImages)

        guard let apngData = APNGEncoder.encode(
            frames: trimmedImages,
            delayTime: frameDelay,
            loopCount: 0
        ) else { return nil }

        // SMALL만 크기 검증 (BIG은 용량 제한 없음)
        if size == .small && apngData.count > maxFileSizeBytes { return nil }

        guard let dir = stickerDirectory(for: size) else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("\(keyringID).png")

        return (try? apngData.write(to: fileURL, options: .atomic)) != nil ? fileURL : nil
    }

    /// 모든 프레임의 alpha > 0 영역을 union 한 bounding box로 일괄 crop
    ///
    /// 각 프레임별 bbox를 개별 적용하면 프레임마다 캔버스 크기가 달라져
    /// APNG로 인코딩할 수 없으므로 union을 사용한다.
    /// CGImage.cropping(to:)는 픽셀 복사 없이 새 view만 만들어 비용 거의 0.
    private static func trimTransparentEdges(_ images: [UIImage]) -> [UIImage] {
        guard !images.isEmpty else { return images }

        // 1) 각 프레임 bbox 계산 + union
        var unionRect: CGRect?
        for image in images {
            guard let cgImage = image.cgImage,
                  let bbox = visibleBoundingBox(of: cgImage) else { continue }
            unionRect = unionRect?.union(bbox) ?? bbox
        }
        guard let trimRect = unionRect else { return images }

        // 2) 잘릴 게 없으면 (이미 캔버스 == 비주얼) skip
        if let first = images.first?.cgImage,
           Int(trimRect.minX) == 0,
           Int(trimRect.minY) == 0,
           Int(trimRect.width) == first.width,
           Int(trimRect.height) == first.height {
            return images
        }

        // 3) 모든 프레임을 동일 bbox로 crop
        return images.compactMap { image in
            guard let cropped = image.cgImage?.cropping(to: trimRect) else { return nil }
            return UIImage(cgImage: cropped)
        }
    }

    /// CGImage의 alpha > 0 픽셀들의 bounding box (좌상단 0,0 기준 픽셀 좌표)
    private static func visibleBoundingBox(of cgImage: CGImage) -> CGRect? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var maxX = -1
        var minY = height
        var maxY = -1

        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                // RGBA premultiplied → alpha는 4번째 바이트
                if pixels[rowOffset + x * 4 + 3] > 0 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        guard maxX >= 0, maxY >= 0 else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    private static func downloadBodyImage(urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
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
