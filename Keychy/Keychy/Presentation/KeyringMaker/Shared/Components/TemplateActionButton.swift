//
//  TemplateActionButton.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

// MARK: - Template Action Button

/// 키링 템플릿 전용 액션 버튼
/// - 보유중이면 "키링 만들기" 버튼 표시 (활성화)
/// - 유료이고 미보유면 구매 버튼 표시
/// - 무료이고 미보유면 "키링 만들기" 버튼 표시 (활성화)
struct TemplateActionButton: View {
    let template: KeyringTemplate
    let isOwned: Bool
    let onMake: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        Group {
            if isOwned || template.isFree {
                // 보유중이거나 무료인 경우 만들기 버튼 (활성화)
                makeButton
            } else {
                // 유료이고 미보유인 경우 구매 버튼
                purchaseButton
            }
        }
    }

    /// 만들기 버튼 (활성화)
    private var makeButton: some View {
        Button {
            onMake()
        } label: {
            Text("키링 만들기")
                .typography(.suit17B)
                .foregroundStyle(.white100)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.main500)
    }

    /// 구매 버튼 (유료)
    private var purchaseButton: some View {
        Button {
            onPurchase()
        } label: {
            HStack(spacing: 5) {
                Image(.myCoinMini)

                Text("\(template.workshopPrice)")
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
