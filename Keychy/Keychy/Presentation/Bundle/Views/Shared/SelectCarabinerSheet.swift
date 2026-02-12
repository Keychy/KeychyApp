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

    /// 3열 그리드 컬럼 설정
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

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

    var body: some View {
        // 그리드만 (필터바는 DraggableSheet header로 이동)
        LazyVGrid(columns: gridColumns, spacing: 20) {
            ForEach(filteredAndSortedCarabiners) { cb in
                Button {
                    onCarabinerTap(cb)

                    if !cb.isOwned && cb.carabiner.isFree {
                        Task {
                            await viewModel.addCarabinerToUser(carabinerName: cb.carabiner.carabinerName, userManager: UserManager.shared)
                        }
                    }
                } label: {
                    CarabinerCell(carabiner: cb, isSelected: (selectedCarabiner == cb))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}
