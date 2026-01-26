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
        HStack(spacing: 0) {
            // 정렬 버튼 (고정)
            sortButton

            Spacer()

            // 퀵 필터 버튼 (무료, 마이)
            quickFilters
        }
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

    // MARK: - 퀵 필터
    /// 퀵 필터 버튼 그룹
    private var quickFilters: some View {
        HStack(spacing: 15) {
            ForEach(QuickFilter.allCases, id: \.self) { filter in
                quickFilterButton(filter)
            }
        }
    }

    /// 퀵 필터 선택 여부
    private func isSelected(_ filter: QuickFilter) -> Bool {
        switch filter {
        case .free: return viewModel.showFreeOnly
        case .owned: return viewModel.showOwnedOnly
        }
    }

    /// 퀵 필터 토글 (라디오 버튼 스타일 - 하나만 선택 가능)
    private func toggle(_ filter: QuickFilter) {
        switch filter {
        case .free:
            viewModel.showFreeOnly.toggle()
            if viewModel.showFreeOnly {
                viewModel.showOwnedOnly = false
            }
        case .owned:
            viewModel.showOwnedOnly.toggle()
            if viewModel.showOwnedOnly {
                viewModel.showFreeOnly = false
            }
        }
    }

    /// 퀵 필터 버튼
    private func quickFilterButton(_ filter: QuickFilter) -> some View {
        Button {
            toggle(filter)
        } label: {
            HStack(spacing: 4) {
                if let icon = filter.icon {
                    Image(icon)
                }
                
                HStack(spacing: 5) {
                    Text(filter.title)
                        .typography(.suit14SB)
                        .foregroundColor(.gray500)
                    
                    Circle()
                        .fill(isSelected(filter) ? Color.main500 : Color.clear)
                        .stroke(.gray100, lineWidth: 1)
                        .frame(width: 16, height: 16)
                        .overlay {
                            if isSelected(filter) {
                                Image(.quickFilterChecked)
                            }
                        }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 카테고리별 필터 옵션, 현재 미사용
    @ViewBuilder
    private var categorySpecificFilters: some View {
        switch viewModel.selectedCategory {
        // 키링 탭: 전체/이미지/텍스트/드로잉은 카테고리 자체가 필터 → 추가 필터 없음
        case "전체", "이미지", "텍스트", "드로잉":
            EmptyView()

        // 뭉치 탭: 카라비너 태그 필터
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

        // 뭉치 탭: 배경 태그 필터
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
