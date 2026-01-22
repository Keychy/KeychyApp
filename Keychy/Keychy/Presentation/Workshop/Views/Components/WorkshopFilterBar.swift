//
//  WorkshopFilterBar.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

// MARK: - Filter Bar

/// 워크샵 필터바 공통 컴포넌트
struct WorkshopFilterBar: View {
    @Binding var viewModel: WorkshopViewModel

    var body: some View {
        HStack(spacing: 8) {
            // 정렬 버튼 (고정)
            sortButton

            // 카테고리별 필터 (스크롤 가능)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categorySpecificFilters
                }
            }
        }
        .padding(.top, 12)
    }

    /// 정렬 버튼
    private var sortButton: some View {
        Button {
            viewModel.showFilterSheet = true
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.sortOrder)
                    .typography(.suit14SB18)
                    .foregroundColor(.gray500)

                Image(systemName: "chevron.down")
                    .foregroundColor(.gray500)
            }
            .padding(.horizontal, Spacing.gap)
            .padding(.vertical, Spacing.sm)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray50)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// 카테고리별 필터 옵션
    private var categorySpecificFilters: some View {
        Group {
            switch viewModel.selectedCategory {
            case "템플릿":
                ForEach(TemplateFilterType.allCases, id: \.self) { filter in
                    WorkshopFilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedTemplateFilter == filter
                    ) {
                        viewModel.selectedTemplateFilter =
                            viewModel.selectedTemplateFilter == filter ? nil : filter
                    }
                }

            case "이펙트":
                ForEach(EffectFilterType.allCases, id: \.self) { filter in
                    WorkshopFilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedEffectFilter == filter
                    ) {
                        viewModel.selectedEffectFilter =
                            viewModel.selectedEffectFilter == filter ? nil : filter
                    }
                }

            case "카라비너":
                ForEach(viewModel.availableCarabinerTags, id: \.self) { tag in
                    WorkshopFilterChip(
                        title: tag,
                        isSelected: viewModel.selectedCommonFilter == tag
                    ) {
                        viewModel.selectedCommonFilter =
                            viewModel.selectedCommonFilter == tag ? nil : tag
                    }
                }

            case "배경":
                ForEach(viewModel.availableBackgroundTags, id: \.self) { tag in
                    WorkshopFilterChip(
                        title: tag,
                        isSelected: viewModel.selectedCommonFilter == tag
                    ) {
                        viewModel.selectedCommonFilter =
                            viewModel.selectedCommonFilter == tag ? nil : tag
                    }
                }

            default:
                EmptyView()
            }
        }
    }
}
