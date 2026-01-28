//
//  PurchaseHistoryView.swift
//  Keychy
//
//  Created by 길지훈 on 1/28/26.
//

import SwiftUI

struct PurchaseHistoryView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State private var viewModel = PurchaseHistoryViewModel()
    @Environment(UserManager.self) private var userManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.receipts) { receipt in
                    historyCard(receipt: receipt)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("구매 내역")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            backToolbarItem
        }
        .onAppear {
            Task {
                if let userId = userManager.currentUser?.id {
                    await viewModel.fetchReceipts(userId: userId)
                }
            }
        }
    }
}

// MARK: - 컴포넌트
extension PurchaseHistoryView {
    private func historyCard(receipt: Receipt) -> some View {
        VStack(spacing: 0) {
            
            /// 아이템 이름 & 가격
            HStack {
                Text("\(receipt.itemName)")
                    .typography(.notosans15M)
                    .foregroundStyle(.black100)
                Spacer()
                HStack(spacing: 4) {
                    Image(.myCoinMini)
                    Text("\(receipt.price)")
                        .typography(.nanum16EB)
                }
            }
            .padding(.bottom, 2)
            
            /// 아이템 타입
            HStack {
                Text("\(receipt.itemTypeDisplayName)")
                    .typography(.notosans12M)
                    .foregroundStyle(.gray400)
                    .padding(.bottom, 10)
                Spacer()
            }
            
            /// 결제 일시
            HStack(spacing: 6) {
                Text("결제 일시")
                Text("\(receipt.purchasedAtFormatted)")
                Spacer()
            }
            .typography(.suit10SB)
            .foregroundStyle(.gray400)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16.62)
        .background(Color.gray50)
        .clipShape(.rect(cornerRadius: 12))
    }
}


// MARK: - Toolbar Items
extension PurchaseHistoryView {
    var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(.backIcon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
    }
}
