//
//  WorkshopBundleGridView.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

/// 뭉치 탭 그리드 뷰 (카라비너, 배경 표시)
/// 카테고리: 카라비너, 배경
struct WorkshopBundleGridView: View {
    @Bindable var viewModel: WorkshopViewModel
    @Bindable var router: NavigationRouter<WorkshopRoute>

    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else {
                if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    bundleGridContent
                }
            }
        }
        .background(.white100)
    }

    /// 뭉치 그리드 콘텐츠 (카테고리별)
    @ViewBuilder
    private var bundleGridContent: some View {
        switch viewModel.selectedCategory {
        case "카라비너":
            WorkshopGridBuilder.itemGridView(
                items: viewModel.filteredCarabiners,
                isOwnedCheck: viewModel.isCarabinerOwned,
                router: router,
                viewModel: viewModel,
                emptyView: emptyContentView
            )
        case "배경":
            WorkshopGridBuilder.itemGridView(
                items: viewModel.filteredBackgrounds,
                isOwnedCheck: viewModel.isBackgroundOwned,
                router: router,
                viewModel: viewModel,
                emptyView: emptyContentView
            )
        default:
            emptyContentView
        }
    }

    /// 로딩 뷰 (스켈레톤)
    private var loadingView: some View {
        HStack(spacing: 11) {
            WorkshopSkeletonBox(width: twoGridCellWidth, height: twoSquareGridCellSize)
            WorkshopSkeletonBox(width: twoGridCellWidth, height: twoSquareGridCellSize)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 92)
    }

    /// 빈 콘텐츠 뷰
    private var emptyContentView: some View {
        VStack(spacing: 12) {
            Image(.emptyViewIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90)

            Text("준비중이에요")
                .typography(.suit14SB18)
                .foregroundColor(.gray500)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }

    /// 에러 뷰
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                Task {
                    await viewModel.fetchAllData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 100)
    }
}
