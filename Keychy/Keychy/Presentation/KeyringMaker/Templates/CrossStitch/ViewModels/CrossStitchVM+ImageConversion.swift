//
//  CrossStitchVM+ImageConversion.swift
//  Keychy
//
//  Created by Jini on 3/10/26.
//

import SwiftUI
import UIKit

// MARK: - Image Conversion
extension CrossStitchVM {

    /// 크로스스티치 그리드를 UIImage로 변환
    /// 각 셀을 stitchImage로 렌더링
    func convertGridToImage(cellSize: CGFloat = 32) async -> UIImage? {
        let count = gridSize
        let totalSize = cellSize * CGFloat(count)
        let imageSize = CGSize(width: totalSize, height: totalSize)

        return await MainActor.run {
            let renderer = UIGraphicsImageRenderer(size: imageSize)
            return renderer.image { context in
                UIColor.clear.setFill()
                context.fill(CGRect(origin: .zero, size: imageSize))

                for row in 0..<count {
                    for col in 0..<count {
                        let stitchColor = stitchGrid[row][col]
                        let stitchRes = stitchColor.stitchImage
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )
                        UIImage(resource: stitchRes).draw(in: rect)
                    }
                }
            }
        }
    }

    /// bodyImage 업데이트 (커스터마이징 뷰로 이동하기 전 호출)
    func updateBodyImage() async {
        guard let image = await convertGridToImage() else {
            print("크로스스티치 이미지 생성 실패")
            return
        }
        await MainActor.run {
            bodyImage = image
            hookOffsetY = 0.0
        }
    }
}
