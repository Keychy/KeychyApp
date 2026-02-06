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

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topLeading) {
                // 카라비너 이미지
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
                        Image(.paidIcon)
                            .padding(.top, 3)
                            .opacity(carabiner.carabiner.isFree ? 0 : 1)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 3)
                .padding(.leading, 7)
                
                // 오른쪽 상단: 유료 아이템만 표시 (보유/가격)
                if !carabiner.carabiner.isFree {
                    VStack {
                        HStack {
                            Spacer()
                            if carabiner.isOwned {
                                // 유료 + 보유
                                Text("보유")
                                    .typography(.suit12M)
                                    .foregroundStyle(.white100)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 1.5)
                                    .background(.black60)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                // 유료 + 미보유: 가격 표시
                                Text("\(carabiner.carabiner.price)")
                                    .typography(.nanum13EB)
                                    .foregroundStyle(.white100)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4.25)
                                    .padding(.top, 2)
                                    .background(.mainOpacity80)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
            } //: ZSTACK
            .clipped()
            Text(carabiner.carabiner.carabinerName)
                .typography(isSelected ? .notosans14SB : .notosans14M)
                .foregroundStyle(isSelected ? .main500 : .black100)
        }
        .contentShape(Rectangle())
    }
}
