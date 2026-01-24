//
//  WorkshopSortSheet.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

// MARK: - Sort Option

/// 정렬 옵션 행
struct SortOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .typography(.suit16M)
                    .foregroundColor(.black100)

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Sort Sheet

/// 정렬 선택 시트
struct WorkshopSortSheet: View {
    @Binding var showSheet: Bool
    @Binding var sortOrder: String

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button {
                    showSheet = false
                } label: {
                    Image(.dismissGray600)
                        .resizable()
                        .frame(width: 24, height: 24)
                }

                Spacer()

                Text("정렬 기준")
                    .typography(.suit15B25)

                Spacer()

                Color.clear
                    .frame(width: 24)
            }
            .padding()

            // 정렬 옵션
            VStack(spacing: 0) {
                ForEach(["최신순", "인기순"], id: \.self) { sort in
                    SortOption(
                        title: sort,
                        isSelected: sortOrder == sort
                    ) {
                        sortOrder = sort
                        showSheet = false
                    }
                }
            }

            Spacer()
        }
        .presentationDetents([.height(200)])
    }
}
