//
//  WorkshopView+MainContent.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - Main Content Section

extension WorkshopView {
    /// 메인 콘텐츠 영역 (키링/뭉치 탭에 따른 그리드)
    var mainContentSection: some View {
        Group {
            if viewModel.workshopToggle {
                // 키링 탭: 템플릿 그리드
                WorkshopKeyringGridView(viewModel: viewModel, router: router)
            } else {
                // 뭉치 탭: 카라비너/배경 그리드
                WorkshopBundleGridView(viewModel: viewModel, router: router)
            }
        }
    }

}


