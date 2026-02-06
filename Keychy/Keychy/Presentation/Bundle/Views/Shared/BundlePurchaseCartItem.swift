//
//  BundlePurchaseCartItem.swift
//  Keychy
//
//  Created by 길지훈 on 2/5/26.
//

import SwiftUI

/// 구매 시트에서 사용하는 장바구니 아이템 행
struct BundlePurchaseCartItem: View {
    let name: String
    let type: String
    let price: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(.selectedIcon)

            Text(name)
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.trailing, 7)

            Text(type)
                .typography(.suit13M)
                .foregroundStyle(.gray400)

            Spacer()

            Text("\(price)")
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray50)
        )
    }
}
