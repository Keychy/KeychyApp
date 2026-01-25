//
//  WorkshopKeyringGridView.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

/// 키링 탭 그리드 뷰 (템플릿 표시)
/// 카테고리: 전체, 이미지, 텍스트, 드로잉
struct WorkshopKeyringGridView: View {
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
                    templateGridContent
                }
            }
        }
        .background(.white100)
    }

    /// 필터링된 템플릿 목록
    private var filteredTemplates: [KeyringTemplate] {
        switch viewModel.selectedCategory {
        case "전체":
            return viewModel.filteredTemplates
        case "이미지":
            return viewModel.templates.filter { $0.tags.contains("이미지") }
        case "텍스트":
            return viewModel.templates.filter { $0.tags.contains("텍스트") }
        case "드로잉":
            return viewModel.templates.filter { $0.tags.contains("드로잉") }
        default:
            return viewModel.filteredTemplates
        }
    }

    /// 템플릿 그리드 콘텐츠
    private var templateGridContent: some View {
        WorkshopGridBuilder.itemGridView(
            items: filteredTemplates,
            isOwnedCheck: viewModel.isTemplateOwned,
            router: router,
            viewModel: viewModel,
            emptyView: emptyContentView
        )
    }

    /// 로딩 뷰 (스켈레톤)
    private var loadingView: some View {
        HStack(spacing: 11) {
            WorkshopSkeletonBox(width: twoGridCellWidth, height: twoGridCellHeight)
            WorkshopSkeletonBox(width: twoGridCellWidth, height: twoGridCellHeight)
        }
        .padding(.horizontal, 16)
        .padding(.top, 80)
        .padding(.bottom, 92)
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
