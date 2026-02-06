//
//  BundleSheetFilterBar.swift
//  Keychy
//
//  Created by 길지훈 on 2/6/26.
//

import SwiftUI

/// 뭉치 생성/편집 시트에서 사용하는 필터바
/// 공방과 달리 정렬 버튼에 배경색이 없음
struct BundleSheetFilterBar: View {
    @Bindable var viewModel: BundleViewModel

    var body: some View {
        HStack(spacing: 0) {
            // 정렬 버튼 (배경 없음)
            sortButton

            Spacer()

            // 퀵 필터 버튼 (무료, 마이)
            quickFilters
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color.clear)
        .contentShape(Rectangle())
    }

    /// 정렬 버튼 (배경색 없음)
    private var sortButton: some View {
        Button {
            viewModel.showSheetSortSheet = true
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.sheetSortOrder)
                    .typography(.suit14SB18)
                    .foregroundColor(.gray500)

                Image(systemName: "chevron.down")
                    .foregroundColor(.gray500)
            }
            .padding(.vertical, Spacing.sm)
            .frame(height: 34)
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// 퀵 필터 버튼 그룹
    private var quickFilters: some View {
        HStack(spacing: 15) {
            quickFilterButton(title: "무료", icon: nil, isSelected: viewModel.sheetShowFreeOnly) {
                viewModel.sheetShowFreeOnly.toggle()
                if viewModel.sheetShowFreeOnly {
                    viewModel.sheetShowOwnedOnly = false
                }
            }

            quickFilterButton(title: "마이", icon: .workshopOwnedIcon, isSelected: viewModel.sheetShowOwnedOnly) {
                viewModel.sheetShowOwnedOnly.toggle()
                if viewModel.sheetShowOwnedOnly {
                    viewModel.sheetShowFreeOnly = false
                }
            }
        }
    }

    /// 퀵 필터 버튼
    private func quickFilterButton(
        title: String,
        icon: ImageResource?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(icon)
                }

                HStack(spacing: 5) {
                    Text(title)
                        .typography(.suit14SB)
                        .foregroundColor(.gray500)

                    Circle()
                        .fill(isSelected ? Color.main500 : Color.clear)
                        .stroke(.gray100, lineWidth: 1)
                        .frame(width: 16, height: 16)
                        .overlay {
                            if isSelected {
                                Image(.quickFilterChecked)
                            }
                        }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
