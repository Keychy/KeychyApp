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

    private let columnCount = 3

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

    /// 3열 행 단위로 분할
    private var rows: [[BackgroundViewData]] {
        let items = filteredAndSortedBackgrounds
        return stride(from: 0, to: items.count, by: columnCount).map {
            Array(items[$0..<min($0 + columnCount, items.count)])
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row) { bg in
                        Button {
                            onBackgroundTap(bg)
                        } label: {
                            BackgroundCell(background: bg, isSelected: (bg == selectedBG), useThumbnail: true)
                        }
                        .buttonStyle(.plain)
                    }
                    // 마지막 행이 3개 미만일 때 빈 공간 채우기
                    if row.count < columnCount {
                        ForEach(0..<(columnCount - row.count), id: \.self) { _ in
                            Color.clear
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}
