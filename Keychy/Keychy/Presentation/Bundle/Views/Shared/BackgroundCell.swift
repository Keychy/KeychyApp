//
//  SelectBackgroundGridItem.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI
import NukeUI

struct BackgroundCell: View {
    let background: BackgroundViewData
    let isSelected: Bool
    var useThumbnail: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .top) {
                cellImageContent
                    .frame(width: threeSquareGridCellSize, height: threeSquareGridCellSize)
                    .background(.white100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? .main500 : .clear, lineWidth: 2)
                    )
                VStack {
                    HStack {
                        // 유료 아이콘
                        Image(.myCoinMini)
                            .opacity(background.background.isFree ? 0 : 1)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                // 오른쪽 상단: 유료 아이템만 표시 (보유/가격)
                if !background.background.isFree {
                    VStack {
                        HStack {
                            Spacer()
                            if background.isOwned {
                                // 유료 + 보유
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.black60)
                                        .frame(width: 38, height: 20)
                                    
                                    Text("보유")
                                        .typography(.suit12M)
                                        .foregroundStyle(.white100)
                                }
                                
                            } else {
                                // 유료 + 미보유: 가격 표시
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.mainOpacity80)
                                        .frame(width: 38,height: 20)
                                    
                                    Text("\(background.background.price)")
                                        .typography(.nanum13EB)
                                        .foregroundStyle(.white100)
                                        .padding(.top, 1)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 7)
                    .padding(.trailing, 8)
                }
            }
            // 이름 라벨
            Text(background.background.backgroundName)
                .typography(isSelected ? .notosans14SB : .notosans14M)
                .foregroundStyle(isSelected ? .main500 : .black100)
        }
        .contentShape(Rectangle())
    }

    /// Lottie / 정적 이미지 분기 (공통 모디파이어는 호출처에서 적용)
    @ViewBuilder
    private var cellImageContent: some View {
        if background.background.isLottie && !useThumbnail, let bgId = background.background.id {
            LottieItemView(
                assetId: bgId,
                directory: "lottie_backgrounds"
            )
        } else {
            LazyImage(url: URL(string: background.background.backgroundImage)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else if state.isLoading {
                    LoadingAlert(type: .short30, message: nil)
                }
            }
        }
    }
}
