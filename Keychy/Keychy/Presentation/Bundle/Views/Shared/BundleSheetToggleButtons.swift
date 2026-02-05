//
//  BundleSheetToggleButtons.swift
//  Keychy
//
//  Created by Claude on 2/5/26.
//

import SwiftUI

/// 뭉치 생성/편집 화면에서 배경/카라비너 시트를 토글하는 버튼 컴포넌트
struct BundleSheetToggleButtons: View {
    @Binding var showBackgroundSheet: Bool
    @Binding var showCarabinerSheet: Bool

    var body: some View {
        HStack(spacing: 8) {
            backgroundButton
            carabinerButton
            Spacer()
        }
        .padding(.leading, 18)
        .padding(.bottom, 10)
    }

    private var backgroundButton: some View {
        Button {
            showBackgroundSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showBackgroundSheet ? .backgroundIconWhite100 : .backgroundIconGray600)
                Text("배경")
                    .typography(.suit9SB)
                    .foregroundStyle(showBackgroundSheet ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(showBackgroundSheet ? .main500 : .white100)
            )
        }
        .buttonStyle(.plain)
    }

    private var carabinerButton: some View {
        Button {
            showCarabinerSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showCarabinerSheet ? .carabinerIconWhite100 : .carabinerIconGray600)
                Text("카라비너")
                    .typography(.suit9SB)
                    .foregroundStyle(showCarabinerSheet ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(showCarabinerSheet ? .main500 : .white100)
            )
        }
        .buttonStyle(.plain)
    }
}
