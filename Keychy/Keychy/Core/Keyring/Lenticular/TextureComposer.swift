//
//  TextureComposer.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import UIKit

/// 렌티큘러 아틀라스 합성기
/// - 이미지 A(좌)와 B(우)를 가로로 합성하여 셰이더용 텍스처 생성
/// - 결과: targetSize.width × 2 너비의 아틀라스 (예: 600×390)
enum TextureComposer {

    /// 두 이미지를 가로 합성하여 아틀라스 생성
    /// - Parameters:
    ///   - imageA: 왼쪽 이미지 (tilt=0일 때 보이는 이미지)
    ///   - imageB: 오른쪽 이미지 (tilt=1일 때 보이는 이미지)
    ///   - targetSize: 한 장의 크기 (예: 300×390)
    ///   - cornerRadius: 라운드 코너 반경
    /// - Returns: 합성된 아틀라스 이미지 (targetSize.width*2 × targetSize.height)
    static func compose(
        imageA: UIImage,
        imageB: UIImage,
        targetSize: CGSize,
        cornerRadius: CGFloat
    ) -> UIImage {
        let atlasSize = CGSize(width: targetSize.width * 2, height: targetSize.height)
        let renderer = UIGraphicsImageRenderer(size: atlasSize)

        return renderer.image { context in
            let cgContext = context.cgContext

            // 좌측: 이미지 A (라운드 코너)
            drawImage(
                imageA,
                in: CGRect(origin: .zero, size: targetSize),
                cornerRadius: cornerRadius,
                context: cgContext
            )

            // 우측: 이미지 B (라운드 코너)
            drawImage(
                imageB,
                in: CGRect(origin: CGPoint(x: targetSize.width, y: 0), size: targetSize),
                cornerRadius: cornerRadius,
                context: cgContext
            )
        }
    }

    /// scaledToFill 방식으로 이미지를 그리고 라운드 코너 클리핑 적용
    private static func drawImage(
        _ image: UIImage,
        in rect: CGRect,
        cornerRadius: CGFloat,
        context: CGContext
    ) {
        context.saveGState()

        // 라운드 코너 클리핑 패스
        let clipPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        context.addPath(clipPath.cgPath)
        context.clip()

        // scaledToFill: 짧은 축 기준으로 스케일 → 중앙 정렬
        let imageSize = image.size
        let fillScale = max(rect.width / imageSize.width,
                            rect.height / imageSize.height)
        let drawSize = CGSize(
            width: imageSize.width * fillScale,
            height: imageSize.height * fillScale
        )
        let drawOrigin = CGPoint(
            x: rect.origin.x + (rect.width - drawSize.width) / 2,
            y: rect.origin.y + (rect.height - drawSize.height) / 2
        )

        image.draw(in: CGRect(origin: drawOrigin, size: drawSize))

        context.restoreGState()
    }
}
