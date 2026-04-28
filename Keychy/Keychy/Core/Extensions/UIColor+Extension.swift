//
//  UIColor+Extension.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-01.
//

import UIKit

extension UIColor {
    /// RGB Float 튜플 추출 (셰이더 uniform 전달용)
    var rgbComponents: (r: Float, g: Float, b: Float) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: nil)
        return (Float(r), Float(g), Float(b))
    }
}
