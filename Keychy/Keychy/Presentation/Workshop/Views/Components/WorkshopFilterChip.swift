//
//  WorkshopFilterChip.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

// MARK: - Filter Chip

/// 필터 칩 버튼
struct WorkshopFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .typography(.suit14SB18)
                    .foregroundColor(isSelected ? Color(.systemBackground) : .gray500)
            }
            .padding(.horizontal, Spacing.gap)
            .padding(.vertical, Spacing.sm)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.black70 : Color.gray50)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
