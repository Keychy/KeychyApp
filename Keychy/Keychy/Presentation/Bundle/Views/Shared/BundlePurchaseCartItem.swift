//
//  BundlePurchaseCartItem.swift
//  Keychy
//
//  Created by 길지훈 on 2/5/26.
//

import SwiftUI
import NukeUI

/// 구매 시트에서 사용하는 장바구니 아이템 행
struct BundlePurchaseCartItem: View {
    let imageURL: String
    let name: String
    let type: String
    let price: Int

    var body: some View {
        HStack(spacing: 12) {
            // 아이템 썸네일 이미지
            if type == "카라비너" {
                LazyImage(url: URL(string: imageURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.isLoading {
                        Color.gray50
                    } else {
                        Color.gray50
                    }
                }
                .padding(2)
                .frame(width: 60, height: 60)
                .background(.white100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                LazyImage(url: URL(string: imageURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if state.isLoading {
                        Color.gray50
                    } else {
                        Color.gray50
                    }
                }
                .frame(width: 60, height: 60)
                .background(.white100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 이름 + 카테고리
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .typography(.suit16B)
                    .foregroundStyle(.black100)

                Text(type)
                    .typography(.suit13M)
                    .foregroundStyle(.gray400)
            }

            Spacer()

            // 가격
            HStack(spacing: 4) {
                Image(.myCoinMini)
                Text("\(price)")
                    .typography(.nanum16EB)
                    .foregroundStyle(.main500)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray50)
        )
    }
}
