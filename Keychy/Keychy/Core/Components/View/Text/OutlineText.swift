//
//  OutlineText.swift
//  Keychy
//
//  Created by 길지훈 on 11/15/25.
//

import SwiftUI

/// 테두리가 있는 텍스트 컴포넌트
struct OutlineText: View {
    let text: String
    let outlineColor: Color
    let outlineWidth: CGFloat
    var directions: Int = 32

    var body: some View {
        ZStack {
            // 테두리 효과 (N방향 — 기본 32방향으로 매끄러�� 아웃라인)
            ForEach(0..<directions, id: \.self) { index in
                Text(text)
                    .foregroundStyle(outlineColor)
                    .offset(x: offset(for: index).width, y: offset(for: index).height)
            }

            // 메인 텍스트 (가장 위)
            Text(text)
        }
    }

    /// N방향 offset 계산
    private func offset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / Double(directions)) * .pi / 180.0
        let x = cos(angle) * outlineWidth
        let y = sin(angle) * outlineWidth
        return CGSize(width: x, height: y)
    }
}

// MARK: - View Extension
extension View {
    /// 텍스트에 테두리를 추가합니다
    /// - Parameters:
    ///   - color: 테두리 색상
    ///   - width: 테두리 두께 (기본값: 1)
    ///   - directions: 아웃라인 방향 수 (기본값: 32, 높을수록 매끄러움)
    func textOutline(color: Color, width: CGFloat = 1, directions: Int = 32) -> some View {
        modifier(TextOutlineModifier(outlineColor: color, outlineWidth: width, directions: directions))
    }
}

// MARK: - ViewModifier
private struct TextOutlineModifier: ViewModifier {
    let outlineColor: Color
    let outlineWidth: CGFloat
    let directions: Int

    func body(content: Content) -> some View {
        ZStack {
            ForEach(0..<directions, id: \.self) { index in
                content
                    .foregroundStyle(outlineColor)
                    .offset(x: offset(for: index).width, y: offset(for: index).height)
            }

            // 메인 텍스트 (가장 위)
            content
        }
    }

    private func offset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / Double(directions)) * .pi / 180.0
        let x = cos(angle) * outlineWidth
        let y = sin(angle) * outlineWidth
        return CGSize(width: x, height: y)
    }
}
