//
//  BundleSheetToggleButtons.swift
//  Keychy
//
//  Created by 길지훈 on 2/5/26.
//

import SwiftUI

/// 뭉치 생성/편집 화면에서 배경/카라비너 시트를 토글하는 버튼 컴포넌트
struct BundleSheetToggleButtons: View {
    @Binding var showItemSheet: Bool
    @Binding var isBackgroundMode: Bool  // true: 배경, false: 카라비너

    private var isBackgroundSelected: Bool {
        showItemSheet && isBackgroundMode
    }

    private var isCarabinerSelected: Bool {
        showItemSheet && !isBackgroundMode
    }

    var body: some View {
        HStack(spacing: 8) {
            backgroundButton
            carabinerButton
            Spacer()
        }
        .padding(.leading, 18)
    }

    private var backgroundButton: some View {
        Button {
            if isBackgroundSelected {
                // 배경 모드에서 다시 누르면 시트 닫기
                showItemSheet = false
            } else {
                // 시트 열기 + 배경 모드로 전환
                isBackgroundMode = true
                showItemSheet = true
            }
        } label: {
            VStack(spacing: 0) {
                Image(isBackgroundSelected ? .backgroundIconWhite100 : .backgroundIconGray600)
                Text("배경")
                    .typography(.suit9SB)
                    .foregroundStyle(isBackgroundSelected ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(isBackgroundSelected ? .main500 : .white100)
            )
            .animation(nil, value: showItemSheet)
            .animation(nil, value: isBackgroundMode)
        }
        .buttonStyle(.plain)
    }

    private var carabinerButton: some View {
        Button {
            if isCarabinerSelected {
                // 카라비너 모드에서 다시 누르면 시트 닫기
                showItemSheet = false
            } else {
                // 시트 열기 + 카라비너 모드로 전환
                isBackgroundMode = false
                showItemSheet = true
            }
        } label: {
            VStack(spacing: 0) {
                Image(isCarabinerSelected ? .carabinerIconWhite100 : .carabinerIconGray600)
                Text("카라비너")
                    .typography(.suit9SB)
                    .foregroundStyle(isCarabinerSelected ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(isCarabinerSelected ? .main500 : .white100)
            )
            .animation(nil, value: showItemSheet)
            .animation(nil, value: isBackgroundMode)
        }
        .buttonStyle(.plain)
    }
}
