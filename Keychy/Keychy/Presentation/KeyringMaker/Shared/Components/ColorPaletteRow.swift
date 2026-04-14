//
//  ColorPaletteRow.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//
//  컬러 팔레트 행 — ColorPicker + 프리셋 원형 셀
//  Binding<Color> 기반으로 다른 템플릿에서도 재사용 가능
//

import SwiftUI

struct ColorPaletteRow: View {
    @Binding var selectedColor: Color
    var presetColors: [Color] = Self.defaultPresets

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 11) {
                // 무지개 ColorPicker (커스텀 색상 선택)
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .scaleEffect(1.4)
                    .frame(width: 36, height: 36)

                // 프리셋 색상들
                ForEach(presetColors.indices, id: \.self) { index in
                    presetCircle(color: presetColors[index])
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 프리셋 원형 셀
    @ViewBuilder
    private func presetCircle(color: Color) -> some View {
        Button {
            selectedColor = color
            Haptic.impact(style: .light)
        } label: {
            Circle()
                .fill(color)
                .frame(width: 37, height: 37)
                .overlay(
                    Circle()
                        .strokeBorder(Color.black20, lineWidth: color == .white100 ? 1 : 0)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                )
                .shadow(color: selectedColor == color ? Color.black.opacity(0.5) : Color.clear, radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 기본 프리셋 색상
extension ColorPaletteRow {
    static let defaultPresets: [Color] = [
        .black100,
        .white100,
        Color(#colorLiteral(red: 1, green: 0.3203514516, blue: 0.2981454134, alpha: 1)),
        Color(#colorLiteral(red: 1, green: 0.5137254902, blue: 0.1411764706, alpha: 1)),
        Color(#colorLiteral(red: 0.1725490196, green: 0.3803921569, blue: 1, alpha: 1)),
        Color(#colorLiteral(red: 0.1882352941, green: 0.1607843137, blue: 0.4862745098, alpha: 1)),
        Color(#colorLiteral(red: 0.6588235294, green: 0.07450980392, blue: 0.4156862745, alpha: 1)),
        Color(#colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)),
        Color(#colorLiteral(red: 0.6431372549, green: 0.8823529412, blue: 1, alpha: 1)),
        Color(#colorLiteral(red: 1, green: 0.768627451, blue: 0.8588235294, alpha: 1)),
    ]
}
