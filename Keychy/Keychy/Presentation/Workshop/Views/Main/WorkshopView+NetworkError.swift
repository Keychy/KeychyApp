//
//  WorkshopView+NetworkError.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - Network Error

extension WorkshopView {
    /// 네트워크 에러 화면
    var networkErrorView: some View {
        ZStack(alignment: .top) {
            NoInternetView(topPadding: getSafeAreaTop() + 40, onRetry: {
                Task {
                    await viewModel.retryFetchAllData()
                }
            })
            .ignoresSafeArea()

            // 고정 타이틀 바 (항상 표시)
            HStack {
                titleView
                Spacer()
                makeBtn
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .background(Color.white100)
        }
    }
}
