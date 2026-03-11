//
//  StitchColor.swift
//  Keychy
//
//  Created by Jini on 3/11/26.
//

import SwiftUI

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
