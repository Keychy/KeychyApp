//
//  BundleEditView+Purchase.swift
//  Keychy
//
//  Created by 김서현 on 1/13/26.
//
// 뭉치 편집뷰의 구매 관련 로직을 모아놓은 파일입니다.
import SwiftUI

extension BundleEditView {
    var purchaseSheetView: some View {
        VStack(spacing: 12) {
            // 상단 섹션 - 닫기 버튼, 타이틀
            HStack {
                Button {
                    showPurchaseSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray600)
                }
                Spacer()
                Text("구매하기")
                    .typography(.suit17B)
                    .foregroundStyle(.gray600)
                Spacer()
            }
            .padding(EdgeInsets(top: 30, leading: 20, bottom: 10, trailing: 20))

            // 구매할 아이템 목록
            VStack(spacing: 20) {
                if let bg = bundleVM.newSelectedBackground, !bg.isOwned && bg.background.price > 0 {
                    BundlePurchaseCartItem(
                        imageURL: bg.background.backgroundImage,
                        name: bg.background.backgroundName,
                        type: "배경",
                        price: bg.background.price
                    )
                }
                if let cb = bundleVM.newSelectedCarabiner, !cb.isOwned && cb.carabiner.price > 0 {
                    BundlePurchaseCartItem(
                        imageURL: cb.carabiner.carabinerImage.first ?? "",
                        name: cb.carabiner.carabinerName,
                        type: "카라비너",
                        price: cb.carabiner.price
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)

            Spacer()

            // 내 보유 재화와 총 가격 (하단 고정)
            HStack(spacing: 6) {
                Text("내 보유 : ")
                    .typography(.suit15M25)
                    .foregroundStyle(.black100)
                    .padding(.vertical, 4.5)
                Text("\(UserManager.shared.currentUser?.coin ?? 0)")
                    .typography(.nanum16EB)
                    .foregroundStyle(.main500)
            }
            purchaseButton
                .padding(.horizontal, 33.2)
                .adaptiveBottomPadding()
        }
        .background(.white100)
        .presentationDetents([.fraction(0.43)])
    }
    
    // 구매 버튼
    private var purchaseButton: some View {
        Button {
            Task {
                await purchaseItems()
            }
        } label: {
            HStack(spacing: 5) {
                if bundleVM.isPurchasing {
                    ProgressView()
                        .tint(.white100)
                } else {
                    Image(.myCoinMini)
                }

                Text("\(bundleVM.totalCartPrice)")
                    .typography(.nanum18EB)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Text("(\(bundleVM.payableItemsCount)개)")
                    .typography(.suit17SB)
            }
            .foregroundStyle(.white100)
            .frame(maxWidth: .infinity)
            .background(bundleVM.isPurchasing ? .gray400 : .black80)
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
        .disabled(bundleVM.isPurchasing)
    }

    // MARK: - 구매 처리
    private func purchaseItems() async {
        let result = await bundleVM.purchaseSelectedItems()

        switch result {
        case .success:
            // 모든 구매 성공
            await MainActor.run {
                bundleVM.isPurchasing = false
                showPurchaseSheet = false
            }

            // 시트 닫히는 애니메이션 대기
            try? await Task.sleep(for: .seconds(0.3))

            await MainActor.run {
                showPurchaseSuccessAlert = true
                purchasesSuccessScale = 0.3
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchasesSuccessScale = 1.0
                }
            }

            await bundleVM.refreshEditData()

            // 1초 후 알럿 자동 닫기 및 저장 후 화면 이동
            try? await Task.sleep(for: .seconds(1))

            await bundleVM.saveBundleChanges()
            await MainActor.run {
                showPurchaseSuccessAlert = false
                purchasesSuccessScale = 0.3
            }

        case .insufficientCoins, .failed:
            // 구매 실패
            await MainActor.run {
                showPurchaseSheet = false
            }

            // 시트 닫히는 애니메이션 대기
            try? await Task.sleep(for: .seconds(0.3))

            await MainActor.run {
                showPurchaseFailAlert = true
                purchaseFailScale = 0.3
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseFailScale = 1.0
                }
            }
        }
    }
}
