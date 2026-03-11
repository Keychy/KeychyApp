//
//  CarabinerSelectItemTile.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SwiftUI
import NukeUI

struct CarabinerCell: View {
    var carabiner: CarabinerViewData
    var isSelected: Bool
    var useThumbnail: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topLeading) {
                cellImageContent
                    .padding(3.55)
                    .frame(width: threeSquareGridCellSize, height: threeSquareGridCellSize)
                    .background(.white100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? .mainOpacity80 : .clear, lineWidth: 1.8)
                    )
                
                // 유료 재화 표시
                VStack {
                    HStack {
                        // 유료 아이콘
                        Image(.myCoinMini)
                            .opacity(carabiner.carabiner.isFree ? 0 : 1)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    Spacer()
                }
                
                // 오른쪽 상단: 유료 아이템만 표시 (보유/가격)
                if !carabiner.carabiner.isFree {
                    VStack {
                        HStack {
                            Spacer()
                            if carabiner.isOwned {
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
                                    
                                    Text("\(carabiner.carabiner.price)")
                                        .typography(.nanum13EB)
                                        .foregroundStyle(.white100)
                                        .padding(.top, 1)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
            } //: ZSTACK
            .clipped()
            HStack(spacing: 4) {
                if carabiner.carabiner.isLottie {
                    Image(.lottieIcon)
                        .resizable()
                        .frame(width: 15, height: 15)
                }
                Text(carabiner.carabiner.carabinerName)
                    .typography(isSelected ? .notosans14SB : .notosans14M)
                    .foregroundStyle(isSelected ? .main500 : .black100)
            }
        }
        .contentShape(Rectangle())
    }

    /// Lottie / 정적 이미지 분기 (공통 모디파이어는 호출처에서 적용)
    @ViewBuilder
    private var cellImageContent: some View {
        if carabiner.carabiner.isLottie && !useThumbnail, let carabinerId = carabiner.carabiner.id {
            LottieItemView(
                assetId: carabinerId,
                directory: "lottie_carabiners_back",
                contentMode: .scaleAspectFit
            )
        } else {
            LazyImage(url: URL(string: carabiner.carabiner.carabinerImage[0])) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .clipped()
                } else if state.isLoading {
                    LoadingAlert(type: .short30, message: nil)
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}
