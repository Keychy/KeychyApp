//
//  KeyringFrameCompositor.swift
//  Keychy
//
//  Created by 길지훈 on 2025-03-05.
//

import CoreGraphics
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// 바디이미지를 키링 애니메이션 프레임에 합성하여 왕복 58장 PNG를 생성
///
/// 키링 프레임(frame00~29.png)은 투명 영역이 있는 PNG이며,
/// 해당 영역에 사용자의 바디이미지가 표시된다.
///
/// 레이어 구조 (아래→위):
/// ```
/// [하단] 바디이미지 (프레임별 위치/회전 적용)
/// [상단] 키링 프레임 (체인, 고리, 카라비너)
/// ```
nonisolated enum KeyringFrameCompositor {

    static let frameSize = 1350
    /// 위젯 출력용 크기 (1350에서 합성 후 축소하여 메모리 절약)
    static let outputSize = 700
    static let baseFrameCount = AnimationFrameStorage.baseFrameCount
    static let imageWidth = 588
    static let imageHeight = 632

    /// 바디이미지 y 미세 조정 (양수 = 아래로, 음수 = 위로)
    /// 구멍 위치에 맞게 조절하세요
    static let bodyOffsetY: CGFloat = -30

    /// 프레임별 transform 데이터: (x, y, rotation°)
    /// 디자이너 좌표(y-down) → CG 좌표(y-up) 변환: y 부호 반전
    private static let frameTransforms: [(x: CGFloat, y: CGFloat, rotation: CGFloat)] = [
        (-109.803, -14.373, 27.000), (-109.120, -14.606, 26.824), (-107.132, -15.276, 26.312),
        (-103.922, -16.328, 25.488), ( -99.572, -17.698, 24.376), ( -94.162, -19.312, 23.000),
        ( -87.770, -21.092, 21.384), ( -80.477, -22.958, 19.552), ( -72.369, -24.831, 17.528),
        ( -63.532, -26.635, 15.336), ( -54.059, -28.297, 13.000), ( -44.047, -29.753, 10.544),
        ( -33.598, -30.949,  7.992), ( -22.815, -31.839,  5.368), ( -11.809, -32.390,  2.696),
        (  -0.690, -32.582,  0.000), (  10.429, -32.409, -2.696), (  21.436, -31.876, -5.368),
        (  32.221, -31.005, -7.992), (  42.673, -29.827, -10.544), (  52.689, -28.387, -13.000),
        (  62.166, -26.741, -15.336), (  71.007, -24.952, -17.528), (  79.120, -23.093, -19.552),
        (  86.417, -21.238, -21.384), (  92.813, -19.469, -23.000), (  98.228, -17.864, -24.376),
        ( 102.581, -16.501, -25.488), ( 105.793, -15.454, -26.312), ( 107.783, -14.787, -26.824),
    ]

    // MARK: - 프레임 생성

    /// 바디이미지로 왕복 애니메이션 프레임 PNG Data 배열 생성
    /// 편도 30장 합성 후, 역순 28장을 복사하여 총 58장 반환
    static func generateFrames(from bodyImage: UIImage) -> [Data]? {
        guard let source = bodyImage.cgImage else { return nil }

        guard let resized = centerCropAndResize(source, width: imageWidth, height: imageHeight) else {
            return nil
        }

        // 1) 편도 프레임 합성 (0→29)
        var frames = [Data]()
        frames.reserveCapacity(AnimationFrameStorage.totalFrameCount)

        for i in 0..<baseFrameCount {
            guard let keyringFrame = loadKeyringFrame(index: i) else { return nil }

            let transform = frameTransforms[i]

            guard let composited = composite(
                keyring: keyringFrame,
                userImage: resized,
                x: transform.x,
                y: transform.y,
                rotation: transform.rotation
            ) else { return nil }

            // 1350 → 700 축소 (위젯 메모리 절약)
            guard let scaled = resizeSquare(composited, to: outputSize) else { return nil }
            guard let pngData = encodePNG(scaled) else { return nil }
            frames.append(pngData)
        }

        // 2) 역순 프레임 복사 (28→1) — 양 끝점 제외로 자연스러운 왕복
        for i in stride(from: baseFrameCount - 2, through: 1, by: -1) {
            frames.append(frames[i])
        }

        return frames
    }

    // MARK: - 번들에서 키링 프레임 로드

    private static func loadKeyringFrame(index: Int) -> CGImage? {
        let name = String(format: "frame%02d", index)

        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data)?.cgImage else {
            return nil
        }

        return image
    }

    // MARK: - 합성

    /// 바디이미지를 키링 프레임 뒤에 합성
    private static func composite(
        keyring: CGImage,
        userImage: CGImage,
        x: CGFloat,
        y: CGFloat,
        rotation: CGFloat
    ) -> CGImage? {
        let size = CGFloat(frameSize)

        guard let ctx = CGContext(
            data: nil, width: frameSize, height: frameSize,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let cgCenterX = size / 2 + x
        let cgCenterY = size / 2 + y

        // 1) 바디이미지 (하단 레이어)
        ctx.saveGState()
        ctx.translateBy(x: cgCenterX, y: cgCenterY)
        ctx.rotate(by: -rotation * .pi / 180)
        // bodyOffsetY: 회전 후 로컬 좌표에서 적용 → 회전 중심에 영향 없음
        ctx.translateBy(x: -CGFloat(imageWidth) / 2, y: -CGFloat(imageHeight) - bodyOffsetY)
        ctx.interpolationQuality = .high
        ctx.draw(userImage, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        ctx.restoreGState()

        // 2) 키링 프레임 (상단 레이어 — 투명 영역에 바디이미지가 보임)
        ctx.draw(keyring, in: CGRect(x: 0, y: 0, width: frameSize, height: frameSize))

        return ctx.makeImage()
    }

    // MARK: - 센터 크롭 + 리사이즈

    /// 원본 이미지를 대상 비율로 중앙 크롭 후 리사이즈
    private static func centerCropAndResize(_ source: CGImage, width: Int, height: Int) -> CGImage? {
        let srcW = source.width
        let srcH = source.height

        let targetRatio = CGFloat(width) / CGFloat(height)
        let srcRatio = CGFloat(srcW) / CGFloat(srcH)

        let cropW: Int
        let cropH: Int
        if srcRatio > targetRatio {
            cropH = srcH
            cropW = Int(CGFloat(srcH) * targetRatio)
        } else {
            cropW = srcW
            cropH = Int(CGFloat(srcW) / targetRatio)
        }

        let cropX = (srcW - cropW) / 2
        let cropY = (srcH - cropH) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)

        guard let cropped = source.cropping(to: cropRect) else { return nil }

        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()
    }

    // MARK: - 정사각형 리사이즈

    /// 정사각형 이미지를 지정 크기로 축소
    private static func resizeSquare(_ source: CGImage, to size: Int) -> CGImage? {
        guard let ctx = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))
        return ctx.makeImage()
    }

    // MARK: - PNG 인코딩

    private static func encodePNG(_ cgImage: CGImage) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data, UTType.png.identifier as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}
