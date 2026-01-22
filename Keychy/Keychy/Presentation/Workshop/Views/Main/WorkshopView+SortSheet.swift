//
//  WorkshopView+SortSheet.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - Sort Sheet

extension WorkshopView {
    /// 정렬 선택 시트
    var sortSheet: some View {
        WorkshopSortSheet(
            showSheet: $viewModel.showFilterSheet,
            sortOrder: $viewModel.sortOrder
        )
        .onChange(of: viewModel.sortOrder) { oldValue, newValue in
            viewModel.applySorting()
        }
    }
}
