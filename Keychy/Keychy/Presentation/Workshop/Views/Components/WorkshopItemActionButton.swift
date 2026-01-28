//
//  WorkshopItemActionButton.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

// MARK: - Item Action Button

/// WorkshopItem (배경, 카라비너, 이펙트 등) 전용 액션 버튼
/// - 무료 또는 보유중: 배경/카라비너 → "뭉치에 사용하기", 그 외 → "보유중"
/// - 유료이고 미보유 → 구매 버튼
struct WorkshopItemActionButton: View {
    let item: any WorkshopItem
    let isOwned: Bool
    let onPurchase: () -> Void
    var onUseInBundle: (() -> Void)? = nil

    /// 배경 또는 카라비너인지 확인
    private var isBundleItem: Bool {
        item is Background || item is Carabiner
    }

    /// 무료이거나 보유중인지 확인
    private var isAvailable: Bool {
        item.isFree || isOwned
    }

    var body: some View {
        Group {
            if isAvailable {
                // 무료 또는 보유중
                if isBundleItem {
                    useInBundleButton
                } else {
                    ownedButton
                }
            } else {
                // 유료이고 미보유
                purchaseButton
            }
        }
    }

    /// 뭉치에 사용하기 버튼 (배경/카라비너)
    private var useInBundleButton: some View {
        Button {
            onUseInBundle?()
        } label: {
            Text("뭉치에 사용하기")
                .typography(.suit17B)
                .foregroundStyle(.white100)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.main500)
    }

    /// 보유중 버튼 (파티클/사운드)
    private var ownedButton: some View {
        Button {
            // 동작 없음
        } label: {
            Text("보유중")
                .typography(.suit17B)
                .foregroundStyle(.white100)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.gray400)
        .disabled(true)
    }

    /// 구매 버튼 (유료)
    private var purchaseButton: some View {
        Button {
            onPurchase()
        } label: {
            HStack(spacing: 5) {
                Image(.myCoinMini)

                Text("\(item.workshopPrice)")
                    .typography(.nanum18EB)
                    .foregroundStyle(.white100)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glassProminent)
        .tint(.black80)
    }
}
