//
//  WorkshopItemActionButton.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

// MARK: - Item Action Button

/// WorkshopItem (배경, 카라비너, 이펙트 등) 전용 액션 버튼
/// - 무료면 "무료" 비활성화 버튼
/// - 보유중이면 "보유중" 비활성화 버튼
/// - 유료이고 미보유면 구매 버튼
struct WorkshopItemActionButton: View {
    let item: any WorkshopItem
    let isOwned: Bool
    let onPurchase: () -> Void

    var body: some View {
        Group {
            if item.isFree {
                disabledButton(text: "무료")
            } else if isOwned {
                disabledButton(text: "보유중")
            } else {
                purchaseButton
            }
        }
    }

    /// 비활성화 버튼 (무료 / 보유중)
    private func disabledButton(text: String) -> some View {
        Button {
            // 비활성화 - 아무 동작 없음
        } label: {
            Text(text)
                .typography(.suit17B)
                .foregroundStyle(.gray400)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.white100)
        .disabled(true)
    }

    /// 구매 버튼 (유료)
    private var purchaseButton: some View {
        Button {
            onPurchase()
        } label: {
            HStack(spacing: 5) {
                Image(.myCoinMini)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32)

                Text("\(item.workshopPrice)")
                    .typography(.nanum18EB)
                    .foregroundStyle(.white100)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .buttonStyle(.glassProminent)
        .tint(.black80)
    }
}
