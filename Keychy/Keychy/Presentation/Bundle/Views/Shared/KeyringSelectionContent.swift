//
//  KeyringSelectionContent.swift
//  Keychy
//
//  Created by Claude on 2/6/26.
//

import SwiftUI

/// 키링 선택 시트의 내용물을 담당하는 공유 컴포넌트
/// Create와 Edit에서 동일한 내용을 다른 시트 방식으로 감싸 사용
struct KeyringSelectionContent: View {
    @Binding var searchText: String
    let keyrings: [Keyring]
    let isLoading: Bool
    let gridColumns: [GridItem]
    let cellWidth: CGFloat
    let cellHeight: CGFloat

    /// 현재 선택 위치에서 선택된 키링인지 확인
    let isSelectedHere: (Keyring) -> Bool
    /// 다른 위치에서 이미 선택된 키링인지 확인
    let isSelectedElsewhere: (Keyring) -> Bool
    /// 키링 선택 액션
    let onTapSelect: (Keyring) -> Void
    /// 키링 선택 해제 액션
    let onTapDeselect: (Keyring) -> Void

    var body: some View {
        if isLoading {
            loadingView
        } else if keyrings.isEmpty {
            KeyringEmptyStateView()
        } else {
            contentView
        }
    }

    // MARK: - 로딩 뷰
    private var loadingView: some View {
        VStack {
            LoadingAlert(type: .short40, message: nil)
                .padding(.vertical, 24)
            Text("키링을 불러오고 있어요")
                .typography(.suit15R)
                .foregroundStyle(.black100)
                .padding(.vertical, 15)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - 메인 콘텐츠
    private var contentView: some View {
        VStack(spacing: 20) {
            BundleSearchBar(searchText: $searchText)
                .padding(.top, 45)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(filteredKeyrings, id: \.self) { keyring in
                        KeyringCell(
                            keyring: keyring,
                            isSelectedHere: isSelectedHere(keyring),
                            isSelectedElsewhere: isSelectedElsewhere(keyring),
                            width: cellWidth,
                            height: cellHeight,
                            onTapSelect: {
                                onTapSelect(keyring)
                            },
                            onTapDeselect: {
                                onTapDeselect(keyring)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - 필터링된 키링 목록
    private var filteredKeyrings: [Keyring] {
        if searchText.isEmpty {
            return keyrings
        }
        return keyrings.filter { keyring in
            keyring.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}
