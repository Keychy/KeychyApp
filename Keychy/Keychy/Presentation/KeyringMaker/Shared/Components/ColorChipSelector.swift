//
//  ColorChipSelector.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//
//  컬러 칩 토글 행 — "컬러 1 ●" / "컬러 2 ●" 캡슐 버튼
//  Binding<Color> 기반으로 다른 템플릿에서도 재사용 가능
//

import SwiftUI

struct ColorChipSelector: View {
    let chips: [ColorChipItem]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 11) {
            ForEach(chips.indices, id: \.self) { index in
                chipButton(index: index)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 개별 칩 버튼
    @ViewBuilder
    private func chipButton(index: Int) -> some View {
        let chip = chips[index]
        let isSelected = selectedIndex == index

        Button {
            selectedIndex = index
            Haptic.impact(style: .light)
        } label: {
            HStack(spacing: 5) {
                Text(chip.label)
                    .typography(.suit16M)
                    .foregroundStyle(.gray500)

                // 현재 색상을 보여주는 원형 인디케이터
                Circle()
                    .fill(chip.color.wrappedValue)
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8.5)
            .background(.gray50)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(
                        isSelected ? .main500 : .clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 칩 데이터 모델
struct ColorChipItem {
    let label: String
    let color: Binding<Color>

    init(label: String, color: Binding<Color>) {
        self.label = label
        self.color = color
    }
}
