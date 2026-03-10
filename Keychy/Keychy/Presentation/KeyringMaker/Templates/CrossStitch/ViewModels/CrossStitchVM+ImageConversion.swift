//
//  CrossStitchVM+ImageConversion.swift
//  Keychy
//
//  Created by Jini on 3/10/26.
//

import SwiftUI
import UIKit

// MARK: - Stitch Color
enum StitchColor: String, CaseIterable {
    case white        = "white"
    case cream        = "cream"
    case yellow       = "yellow"
    case orange       = "orange"
    case red          = "red"
    case brown        = "brown"
    case yellowOchre  = "yellowOchre"
    case lightGreen   = "lightGreen"
    case pistachio    = "pistachio"
    case green        = "green"
    case mint         = "mint"
    case lightBlue    = "lightBlue"
    case periwinkleBlue = "periwinkleBlue"
    case blue         = "blue"
    case lavender     = "lavender"
    case purple       = "purple"
    case magenta      = "magenta"
    case opera        = "opera"
    case shellPink    = "shellPink"
    case pink         = "pink"
    case gray         = "gray"
    case charcoal     = "charcoal"
    case black        = "black"
  

    /// 팔레트에서 보여줄 실 이미지
    var threadImage: ImageResource {
        switch self {
        case .white:          return .whiteThread
        case .cream:          return .creamThread
        case .yellow:         return .yellowThread
        case .orange:         return .orangeThread
        case .red:            return .redThread
        case .brown:          return .brownThread
        case .yellowOchre:    return .yellowOchreThread
        case .lightGreen:     return .lightGreenThread
        case .pistachio:      return .pistachioThread
        case .green:          return .greenThread
        case .mint:           return .mintThread
        case .lightBlue:      return .lightBlueThread
        case .periwinkleBlue: return .periwinkleBlueThread
        case .blue:           return .blueThread
        case .lavender:       return .lavenderThread
        case .purple:         return .purpleThread
        case .magenta:        return .magentaThread
        case .opera:          return .operaThread
        case .shellPink:      return .shellPinkThread
        case .pink:           return .pinkThread
        case .gray:           return .grayThread
        case .charcoal:       return .charcoalThread
        case .black:          return .blackThread
        }
    }

    /// 그리드 셀에 보여줄 스티치 이미지
    var stitchImage: ImageResource {
        switch self {
        case .white:          return .whiteStitch
        case .cream:          return .creamStitch
        case .yellow:         return .yellowStitch
        case .orange:         return .orangeStitch
        case .red:            return .redStitch
        case .brown:          return .brownStitch
        case .yellowOchre:    return .yellowOchreStitch
        case .lightGreen:     return .lightGreenStitch
        case .pistachio:      return .pistachioStitch
        case .green:          return .greenStitch
        case .mint:           return .mintStitch
        case .lightBlue:      return .lightBlueStitch
        case .periwinkleBlue: return .periwinkleBlueStitch
        case .blue:           return .blueStitch
        case .lavender:       return .lavenderStitch
        case .purple:         return .purpleStitch
        case .magenta:        return .magentaStitch
        case .opera:          return .operaStitch
        case .shellPink:      return .shellPinkStitch
        case .pink:           return .pinkStitch
        case .gray:           return .grayStitch
        case .charcoal:       return .charcoalStitch
        case .black:          return .blackStitch
        }
    }
}

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
