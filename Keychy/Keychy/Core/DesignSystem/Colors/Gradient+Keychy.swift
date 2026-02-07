//
//  Gradient+Keychy.swift
//  Keychy
//
//  앱 전체에서 사용하는 그라디언트 시스템
//
//  사용법:
//  Rectangle().fill(.gradient(.primary))
//  Text("Hello").foregroundStyle(.gradient(.accent))
//

import SwiftUI

enum GradientStyle {
    case primary
    case festivalPublished
}

extension GradientStyle {
    var gradient: LinearGradient {
        switch self {
        case .primary:
            return LinearGradient(
                colors: [.gradient1, .gradient2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .festivalPublished:
            return LinearGradient(
                colors: [.gradient3, .gradient4],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

extension ShapeStyle where Self == LinearGradient {
    static func gradient(_ style: GradientStyle) -> LinearGradient {
        return style.gradient
    }
}
