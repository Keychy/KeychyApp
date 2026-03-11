//
//  SelectCarabinerSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/14/25.
//

import SwiftUI

struct SelectCarabinerSheet: View {
    @Bindable var viewModel: BundleViewModel
    let selectedCarabiner: CarabinerViewData?
    let onCarabinerTap: (CarabinerViewData) -> Void

    private let columnCount = 3

    /// 필터링 및 정렬된 카라비너 목록
    private var filteredAndSortedCarabiners: [CarabinerViewData] {
        var result = viewModel.carabinerViewData

        // 필터 적용
        if viewModel.sheetShowFreeOnly {
            result = result.filter { $0.carabiner.isFree }
        } else if viewModel.sheetShowOwnedOnly {
            result = result.filter { $0.isOwned }
        }

        // 정렬
        result = result.sorted { cb1, cb2 in
            // 키치 카라비너는 항상 맨 앞
            let isKeychy1 = cb1.carabiner.carabinerName == "키치 카라비너"
            let isKeychy2 = cb2.carabiner.carabinerName == "키치 카라비너"

            if isKeychy1 && !isKeychy2 {
                return true
            } else if !isKeychy1 && isKeychy2 {
                return false
            }

            // 정렬 기준 적용
            switch viewModel.sheetSortOrder {
            case "최신순":
                return cb1.carabiner.createdAt > cb2.carabiner.createdAt
            case "인기순":
                return cb1.carabiner.useCount > cb2.carabiner.useCount
            default:
                return false
            }
        }

        return result
    }

    /// 3열 행 단위로 분할
    private var rows: [[CarabinerViewData]] {
        let items = filteredAndSortedCarabiners
        return stride(from: 0, to: items.count, by: columnCount).map {
            Array(items[$0..<min($0 + columnCount, items.count)])
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row) { cb in
                        Button {
                            onCarabinerTap(cb)
                        } label: {
                            CarabinerCell(carabiner: cb, isSelected: (selectedCarabiner == cb), useThumbnail: true)
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
