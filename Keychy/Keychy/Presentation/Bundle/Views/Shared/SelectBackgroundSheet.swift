//
//  SelectBackgroundSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/14/25.
//

import SwiftUI

struct SelectBackgroundSheet: View {
    @Bindable var viewModel: BundleViewModel
    let selectedBG: BackgroundViewData?
    let onBackgroundTap: (BackgroundViewData) -> Void

    /// 3열 그리드 컬럼 설정
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    /// 필터링 및 정렬된 배경 목록
    private var filteredAndSortedBackgrounds: [BackgroundViewData] {
        var result = viewModel.backgroundViewData

        // 필터 적용
        if viewModel.sheetShowFreeOnly {
            result = result.filter { $0.background.isFree }
        } else if viewModel.sheetShowOwnedOnly {
            result = result.filter { $0.isOwned }
        }

        // 정렬
        result = result.sorted { bg1, bg2 in
            // 키치 배경은 항상 맨 앞
            let isKeychy1 = bg1.background.backgroundName == "키치 배경"
            let isKeychy2 = bg2.background.backgroundName == "키치 배경"

            if isKeychy1 && !isKeychy2 {
                return true
            } else if !isKeychy1 && isKeychy2 {
                return false
            }

            // 정렬 기준 적용
            switch viewModel.sheetSortOrder {
            case "최신순":
                return bg1.background.createdAt > bg2.background.createdAt
            case "인기순":
                return bg1.background.useCount > bg2.background.useCount
            default:
                return false
            }
        }

        return result
    }

    var body: some View {
        // 그리드만 (필터바는 DraggableSheet header로 이동)
        LazyVGrid(columns: gridColumns, spacing: 20) {
            ForEach(filteredAndSortedBackgrounds) { bg in
                Button {
                    onBackgroundTap(bg)
                } label: {
                    BackgroundCell(background: bg, isSelected: (bg == selectedBG))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}
