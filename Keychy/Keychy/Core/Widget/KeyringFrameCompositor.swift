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
/// 키링 프레임(chain{N}_frame00~29.png)은 투명 영역이 있는 PNG이며,
/// 해당 영역에 사용자의 바디이미지가 표시된다.
///
/// 바디 크기는 앱 내 `KeyringScale.maxSize × sceneToFrameScale`로 결정한다.
/// 프레임의 링·체인이 1350px 해상도에 맞춰 디자인되었으므로,
/// 동일한 스케일을 바디에 적용하면 앱과 같은 비율이 된다.
///
/// 레이어 구조 (아래→위):
/// ```
/// [하단] 바디이미지 (프레임별 위치/회전 적용)
/// [상단] 키링 프레임 (체인, 고리, 카라비너)
/// ```
nonisolated enum KeyringFrameCompositor {

    static let frameSize = 1350
    static let baseFrameCount = AnimationFrameStorage.baseFrameCount

    /// 앱 포인트 → 1350px 프레임 픽셀 변환 스케일
    /// 프레임의 링·체인이 이 스케일 기준으로 디자인되어 있음
    private static let sceneToFrameScale: CGFloat = 3.0
    /// 캔버스 가장자리 최소 여백 (바디가 프레임 밖으로 넘치지 않도록 제한)
    private static let minPadding: CGFloat = 50

    // MARK: - 체인별 애니메이션 설정

    /// 체인 길이별 애니메이션 설정값
    /// - transforms: 프레임별 (x, y, rotation°) — 디자이너 좌표(y-down) → CG(y-up) 변환 적용
    /// - frameScale: 프레임 드로잉 스케일 (체인이 짧을수록 전체가 작아짐, 앱과 동일)
    private struct ChainAnimationConfig {
        let transforms: [(x: CGFloat, y: CGFloat, rotation: CGFloat)]
        let frameScale: CGFloat
    }

    /// chain5 프레임별 transform 데이터 (30개)
    private static let chain5Transforms: [(x: CGFloat, y: CGFloat, rotation: CGFloat)] = [
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

    /// chain3 프레임별 transform 데이터 (30개)
    /// 디자이너 좌표(y-down) → CG 좌표(y-up) 변환: y 부호 반전 적용
    private static let chain3Transforms: [(x: CGFloat, y: CGFloat, rotation: CGFloat)] = [
        ( -56.850,  97.051, 18.000), ( -56.492,  96.965, 17.883), ( -55.450,  96.718, 17.541),
        ( -53.770,  96.330, 16.992), ( -51.498,  95.826, 16.251), ( -48.679,  95.232, 15.333),
        ( -45.359,  94.578, 14.256), ( -41.583,  93.892, 13.035), ( -37.398,  93.205, 11.685),
        ( -32.852,  92.544, 10.224), ( -27.992,  91.934,  8.667), ( -22.868,  91.401,  7.029),
        ( -17.533,  90.962,  5.328), ( -12.037,  90.635,  3.579), (  -6.434,  90.431,  1.797),
        (  -0.777,  90.358, -0.000), (   4.881,  90.417, -1.797), (  10.485,  90.607, -3.579),
        (  15.982,  90.920, -5.328), (  21.318,  91.345, -7.029), (  26.443,  91.866, -8.667),
        (  31.305,  92.463, -10.224), (  35.854,  93.113, -11.685), (  40.042,  93.790, -13.035),
        (  43.820,  94.466, -14.256), (  47.142,  95.112, -15.333), (  49.963,  95.699, -16.251),
        (  52.236,  96.198, -16.992), (  53.918,  96.582, -17.541), (  54.961,  96.826, -17.883),
    ]

    /// chain1 프레임별 transform 데이터 (30개)
    /// 디자이너 좌표(y-down) → CG 좌표(y-up) 변환: y 부호 반전 적용
    private static let chain1Transforms: [(x: CGFloat, y: CGFloat, rotation: CGFloat)] = [
        ( -17.810, 175.906,  9.000), ( -17.701, 175.888,  8.941), ( -17.382, 175.838,  8.771),
        ( -16.869, 175.758,  8.496), ( -16.175, 175.655,  8.125), ( -15.316, 175.534,  7.667),
        ( -14.306, 175.400,  7.128), ( -13.160, 175.260,  6.517), ( -11.892, 175.120,  5.843),
        ( -10.516, 174.985,  5.112), (  -9.049, 174.860,  4.333), (  -7.504, 174.750,  3.515),
        (  -5.898, 174.660,  2.664), (  -4.245, 174.591,  1.789), (  -2.561, 174.548,  0.899),
        (  -0.862, 174.530, -0.000), (   0.838, 174.539, -0.899), (   2.522, 174.575, -1.789),
        (   4.175, 174.635, -2.664), (   5.782, 174.718, -3.515), (   7.327, 174.820, -4.333),
        (   8.795, 174.937, -5.112), (  10.171, 175.066, -5.843), (  11.439, 175.200, -6.517),
        (  12.587, 175.335, -7.128), (  13.597, 175.463, -7.667), (  14.457, 175.580, -8.125),
        (  15.151, 175.680, -8.496), (  15.664, 175.757, -8.771), (  15.983, 175.806, -8.941),
    ]

    /// 체인 길이 → 애니메이션 설정 매핑
    private static let chainConfigs: [Int: ChainAnimationConfig] = [
        5: ChainAnimationConfig(transforms: chain5Transforms, frameScale: 0.9),
        3: ChainAnimationConfig(transforms: chain3Transforms, frameScale: 0.7),
        1: ChainAnimationConfig(transforms: chain1Transforms, frameScale: 0.7),
    ]

    // MARK: - 프레임 생성

    /// 바디이미지로 왕복 애니메이션 프레임 PNG Data 배열 생성
    ///
    /// 바디 크기는 `KeyringScale.maxSize(for:) × sceneToFrameScale`로 결정한다.
    /// - Parameters:
    ///   - bodyImage: 사용자 바디이미지
    ///   - chainLength: 체인 길이 (1, 3, 5)
    ///   - template: 템플릿 ID — 바디 크기 및 Y 보정에 사용
    ///   - isGyroscope: 렌티큘러(자이로) 키링 여부 — true면 아틀라스 A|B 블렌딩 적용
    /// - Returns: 편도 30장 + 역순 28장 = 총 58장 PNG Data 배열
    static func generateFrames(
        from bodyImage: UIImage,
        chainLength: Int,
        template: String,
        isGyroscope: Bool = false
    ) -> [Data]? {
        guard let config = chainConfigs[chainLength] ?? chainConfigs[5] else {
            return nil
        }

        // 템플릿 maxSize × sceneToFrameScale → 프레임 픽셀 크기
        let templateSize = KeyringScale.maxSize(for: template)
        let bodyWidth = Int(templateSize.width * sceneToFrameScale)
        let bodyHeight = Int(templateSize.height * sceneToFrameScale)
        let bodyOffsetY = KeyringScale.widgetBodyOffsetY(for: template, bodyImage: bodyImage)

        // 오버플로 방지: 바디가 피벗 아래로 매달리므로 캔버스 기준으로 제한
        let maxAllowed = CGFloat(frameSize) * KeyringScale.widgetBodyClamp(for: template)
        let bodyMaxDim = max(CGFloat(bodyWidth), CGFloat(bodyHeight))
        let bodyClampScale = min(maxAllowed / bodyMaxDim, 1.0)

        guard let source = bodyImage.cgImage else { return nil }

        // 렌티큘러: 아틀라스(A|B 가로 합성)를 좌/우로 분리 후 각각 리사이즈
        // 일반: 단일 이미지를 그대로 리사이즈
        let imageA: CGImage
        let imageB: CGImage?

        if isGyroscope, let (left, right) = splitAtlas(source) {
            guard let resizedA = centerCropAndResize(left, width: bodyWidth, height: bodyHeight),
                  let resizedB = centerCropAndResize(right, width: bodyWidth, height: bodyHeight) else {
                return nil
            }
            imageA = resizedA
            imageB = resizedB
        } else {
            guard let resized = centerCropAndResize(source, width: bodyWidth, height: bodyHeight) else {
                return nil
            }
            imageA = resized
            imageB = nil
        }

        // 프레임 0의 rotation°으로 최대 회전각 결정 (tilt 정규화용)
        let maxRotation = abs(config.transforms[0].rotation)

        // 1) 편도 프레임 합성 (0→29)
        var frames = [Data]()
        frames.reserveCapacity(AnimationFrameStorage.totalFrameCount)

        for i in 0..<baseFrameCount {
            guard let keyringFrame = loadKeyringFrame(index: i, chainLength: chainLength) else {
                return nil
            }

            let transform = config.transforms[i]

            // 렌티큘러: rotation → tilt로 A/B 블렌딩 + 메탈 테두리
            let userImage: CGImage
            if let imgB = imageB {
                let tilt = rotationToTilt(transform.rotation, maxRotation: maxRotation)
                guard let blended = blendImages(
                    imageA: imageA,
                    imageB: imgB,
                    tilt: tilt,
                    width: bodyWidth,
                    height: bodyHeight
                ) else { return nil }
                // 라운드 코너 + 메탈릭 실버 테두리 적용
                guard let bordered = applyLenticularBorder(
                    blended,
                    width: bodyWidth,
                    height: bodyHeight,
                    tilt: tilt
                ) else { return nil }
                userImage = bordered
            } else {
                userImage = imageA
            }

            guard let composited = composite(
                keyring: keyringFrame,
                userImage: userImage,
                bodyWidth: bodyWidth,
                bodyHeight: bodyHeight,
                bodyOffsetY: bodyOffsetY,
                x: transform.x,
                y: transform.y,
                rotation: transform.rotation,
                frameScale: config.frameScale,
                bodyClampScale: bodyClampScale
            ) else { return nil }

            // 1350 → 템플릿별 크기로 축소 (위젯 메모리 절약)
            let outputSize = KeyringScale.widgetOutputSize(for: template)
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

    /// 체인 길이별 프레임 PNG를 로드
    /// 파일명 규칙: chain{N}_frame{00~29}.png
    private static func loadKeyringFrame(index: Int, chainLength: Int) -> CGImage? {
        let name = String(format: "chain%d_frame%02d", chainLength, index)

        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data)?.cgImage else {
            return nil
        }

        return image
    }

    // MARK: - 합성

    /// 바디이미지를 키링 프레임 뒤에 합성
    /// - frameScale: 키링 프레임(링·체인) PNG 스케일 — 체인이 짧을수록 작게
    /// - bodyClampScale: 바디 오버플로 방지용 축소 (보통 1.0)
    private static func composite(
        keyring: CGImage,
        userImage: CGImage,
        bodyWidth: Int,
        bodyHeight: Int,
        bodyOffsetY: CGFloat,
        x: CGFloat,
        y: CGFloat,
        rotation: CGFloat,
        frameScale: CGFloat,
        bodyClampScale: CGFloat
    ) -> CGImage? {
        let size = CGFloat(frameSize)

        guard let ctx = CGContext(
            data: nil, width: frameSize, height: frameSize,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let scaledFrameSize = size * frameScale

        // 프레임을 캔버스 위쪽 정렬 + 상단 여백 (CG 좌표: y가 클수록 위)
        let frameOriginX = (size - scaledFrameSize) / 2
        let frameOriginY = size - scaledFrameSize - minPadding

        // 피벗: 프레임 중심 기준으로 계산
        let frameCenterX = size / 2
        let frameCenterY = size - scaledFrameSize / 2 - minPadding
        let cgCenterX = frameCenterX + x * frameScale
        let cgCenterY = frameCenterY + y * frameScale

        // 바디 크기: 오버플로 방지용 clamp만 적용 (frameScale 영향 없음)
        let clampedBodyW = CGFloat(bodyWidth) * bodyClampScale
        let clampedBodyH = CGFloat(bodyHeight) * bodyClampScale

        // 1) 바디이미지 (하단 레이어) — 템플릿 크기 유지
        ctx.saveGState()
        ctx.translateBy(x: cgCenterX, y: cgCenterY)
        ctx.rotate(by: -rotation * .pi / 180)
        ctx.translateBy(x: -clampedBodyW / 2, y: -clampedBodyH - bodyOffsetY)
        ctx.interpolationQuality = .high
        ctx.draw(userImage, in: CGRect(x: 0, y: 0, width: clampedBodyW, height: clampedBodyH))
        ctx.restoreGState()

        // 2) 키링 프레임 (상단 레이어) — frameScale 적용, 캔버스 위쪽 정렬
        ctx.draw(keyring, in: CGRect(x: frameOriginX, y: frameOriginY, width: scaledFrameSize, height: scaledFrameSize))

        return ctx.makeImage()
    }

    // MARK: - 렌티큘러 블렌딩

    /// 아틀라스(A|B 가로 합성 이미지)를 좌측 A, 우측 B로 분리
    ///
    /// 렌티큘러 바디이미지는 600×390처럼 가로로 두 장이 이어붙은 형태.
    /// `CGImage.cropping(to:)`로 좌/우 절반을 각각 잘라낸다.
    private static func splitAtlas(_ atlas: CGImage) -> (left: CGImage, right: CGImage)? {
        let halfWidth = atlas.width / 2
        let height = atlas.height

        // CGImage.cropping(to:)는 픽셀 좌표 사용 (좌상단 원점)
        let leftRect = CGRect(x: 0, y: 0, width: halfWidth, height: height)
        let rightRect = CGRect(x: halfWidth, y: 0, width: halfWidth, height: height)

        guard let left = atlas.cropping(to: leftRect),
              let right = atlas.cropping(to: rightRect) else {
            return nil
        }
        return (left, right)
    }

    /// rotation°를 0.0~1.0 tilt로 정규화
    ///
    /// - rotation이 +maxRotation(좌측 끝)이면 tilt = 0.0 → 이미지 A
    /// - rotation이 0(중앙)이면 tilt = 0.5 → A+B 블렌딩
    /// - rotation이 -maxRotation(우측 끝)이면 tilt = 1.0 → 이미지 B
    private static func rotationToTilt(_ rotation: CGFloat, maxRotation: CGFloat) -> CGFloat {
        guard maxRotation > 0 else { return 0.5 }
        let normalized = (-rotation / maxRotation + 1.0) / 2.0
        return min(max(normalized, 0.0), 1.0)
    }

    /// 이미지 A와 B를 tilt 비율로 alpha 크로스페이드 블렌딩
    ///
    /// Core Graphics의 `setAlpha()` + `draw()` 2회로 구현.
    /// tilt=0.0이면 A만, tilt=1.0이면 B만, 중간값이면 혼합.
    private static func blendImages(
        imageA: CGImage,
        imageB: CGImage,
        tilt: CGFloat,
        width: Int,
        height: Int
    ) -> CGImage? {
        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)

        // 하단 레이어: 이미지 A (알파 = 1-tilt)
        ctx.setAlpha(1.0 - tilt)
        ctx.draw(imageA, in: rect)

        // 상단 레이어: 이미지 B (알파 = tilt)
        ctx.setAlpha(tilt)
        ctx.draw(imageB, in: rect)

        return ctx.makeImage()
    }

    // MARK: - 렌티큘러 바디 테두리

    /// 블렌딩된 바디이미지에 라운드 코너 + 메탈릭 실버 테두리 적용
    ///
    /// 셰이더 기준값(cornerRadius=12, borderWidth=3)을 sceneToFrameScale(×3)로 변환.
    /// tilt에 따른 밝기 변화: 끝점(tilt 0/1)에서 밝고, 중앙(0.5)에서 어두움.
    private static func applyLenticularBorder(
        _ image: CGImage,
        width: Int,
        height: Int,
        tilt: CGFloat
    ) -> CGImage? {
        let w = CGFloat(width)
        let h = CGFloat(height)
        let cornerRadius: CGFloat = 12.0 * sceneToFrameScale
        let borderWidth: CGFloat = 3.0 * sceneToFrameScale

        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let fullRect = CGRect(x: 0, y: 0, width: w, height: h)
        let roundedPath = CGPath(roundedRect: fullRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        // 1) 라운드 코너 클리핑 후 바디이미지 드로잉
        ctx.saveGState()
        ctx.addPath(roundedPath)
        ctx.clip()
        ctx.interpolationQuality = .high
        ctx.draw(image, in: fullRect)
        ctx.restoreGState()

        // 2) 메탈릭 실버 테두리 — tilt 연동 밝기
        let tiltEdge = abs(tilt * 2.0 - 1.0)
        let brightness = 0.72 + 0.23 * tiltEdge
        guard let borderColor = CGColor(
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            components: [brightness, brightness, brightness, 1.0]
        ) else { return nil }

        let insetRect = fullRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        let borderPath = CGPath(roundedRect: insetRect, cornerWidth: cornerRadius - borderWidth / 2, cornerHeight: cornerRadius - borderWidth / 2, transform: nil)

        ctx.setStrokeColor(borderColor)
        ctx.setLineWidth(borderWidth)
        ctx.addPath(borderPath)
        ctx.strokePath()

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
