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

/// 바디이미지를 키링 애니메이션 프레임에 합성하여 30장 PNG를 생성
///
/// 키링 프레임(keyring_00~29.png)은 투명 영역이 있는 PNG이며,
/// 해당 영역에 사용자의 바디이미지가 표시된다.
///
/// 레이어 구조 (아래→위):
/// ```
/// [하단] 바디이미지 (프레임별 위치/회전 적용)
/// [상단] 키링 프레임 (체인, 고리, 카라비너)
/// ```
nonisolated enum KeyringFrameCompositor {

    static let frameSize = 420
    static let frameCount = AnimationFrameStorage.frameCount
    static let imageWidth = 158
    static let imageHeight = 170

    /// 프레임별 transform 데이터: (x, y, rotation°)
    /// 좌표계: CG 기준 (원점 = 이미지 중앙)
    ///   x: 양수 = 오른쪽
    ///   y: 양수 = 위
    ///   rotation: 양수 = 반시계 방향 (도 단위)
    private static let frameTransforms: [(x: CGFloat, y: CGFloat, rotation: CGFloat)] = [
        (-39.96, -79.84, 12.355),  (-42.22, -80.09, 13.255),  (-44.49, -80.36, 14.155),
        (-46.74, -80.66, 15.055),  (-48.99, -81.00, 15.955),  (-51.23, -81.36, 16.855),
        (-53.47, -81.74, 17.755),  (-55.69, -82.16, 18.655),  (-57.91, -82.60, 19.555),
        (-60.12, -83.07, 20.455),  (-62.32, -83.57, 21.355),  (-51.78, -80.43, 16.755),
        (-41.04, -78.03, 12.155),  (-30.17, -76.38, 7.555),   (-19.22, -75.49, 2.955),
        (4.0,    -72.51, -1.645),  (18.0,   -73.05, -6.245),  (30.0,   -73.83, -10.845),
        (40.0,   -74.87, -15.445), (48.0,   -76.40, -20.045), (53.0,   -78.40, -24.645),
        (49.0,   -76.58, -20.945), (43.0,   -75.47, -17.245), (35.0,   -74.83, -13.545),
        (26.0,   -74.43, -9.845),  (15.0,   -74.50, -6.145),  (4.0,    -75.50, -2.445),
        (-8.0,   -76.50, 1.255),   (-19.0,  -77.80, 4.955),   (-30.0,  -79.00, 8.655),
    ]

    // MARK: - 프레임 생성

    /// 바디이미지로 30장 애니메이션 프레임 PNG Data 배열 생성
    static func generateFrames(from bodyImage: UIImage) -> [Data]? {
        guard let source = bodyImage.cgImage else { return nil }

        guard let resized = centerCropAndResize(source, width: imageWidth, height: imageHeight) else {
            return nil
        }

        var frames = [Data]()
        frames.reserveCapacity(frameCount)

        for i in 0..<frameCount {
            guard let keyringFrame = loadKeyringFrame(index: i) else { return nil }

            let transform = frameTransforms[i]

            guard let composited = composite(
                keyring: keyringFrame,
                userImage: resized,
                x: transform.x,
                y: transform.y,
                rotation: transform.rotation
            ) else { return nil }

            guard let pngData = encodePNG(composited) else { return nil }
            frames.append(pngData)
        }

        return frames
    }

    // MARK: - 번들에서 키링 프레임 로드

    private static func loadKeyringFrame(index: Int) -> CGImage? {
        let name = String(format: "keyring_%02d", index)

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
        ctx.translateBy(x: -CGFloat(imageWidth) / 2, y: -CGFloat(imageHeight) / 2)
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
