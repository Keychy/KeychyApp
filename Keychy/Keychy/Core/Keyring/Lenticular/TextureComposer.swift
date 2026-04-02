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
/// - 라운드 코너는 셰이더(LenticularShader)에서 처리 — 텍스처는 직각 보관
enum TextureComposer {

    /// 두 이미지를 가로 합성하여 아틀라스 생성
    static func compose(
        imageA: UIImage,
        imageB: UIImage,
        targetSize: CGSize
    ) -> UIImage {
        let atlasSize = CGSize(width: targetSize.width * 2, height: targetSize.height)
        let renderer = UIGraphicsImageRenderer(size: atlasSize)

        return renderer.image { context in
            let cgContext = context.cgContext

            // 좌측: 이미지 A
            drawImage(imageA, in: CGRect(origin: .zero, size: targetSize), context: cgContext)

            // 우측: 이미지 B
            drawImage(imageB, in: CGRect(origin: CGPoint(x: targetSize.width, y: 0), size: targetSize), context: cgContext)
        }
    }

    /// scaledToFill 방식으로 이미지를 그림
    private static func drawImage(
        _ image: UIImage,
        in rect: CGRect,
        context: CGContext
    ) {
        context.saveGState()

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
