//
//  BundleCreateView+Alert.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI

// MARK: - Alert 컨텐츠
extension BundleCreateView {
    var alertContent: some View {
        ZStack {
            // 구매 성공 Alert
            if showPurchaseSuccessAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        showPurchaseSuccessAlert = false
                        purchasesSuccessScale = 0.3
                    }

                KeychyAlert(type: .checkmark, message: "구매가 완료되었어요!", isPresented: $showPurchaseSuccessAlert)
                    .zIndex(101)
            }

            // 구매 실패 Alert
            if showPurchaseFailAlert {
                ZStack {
                    Color.black20
                        .ignoresSafeArea()
                        .onTapGesture {
                            showPurchaseFailAlert = false
                            purchaseFailScale = 0.3
                        }

                    PurchaseFailAlert(
                        checkmarkScale: purchaseFailScale,
                        onCancel: {
                            showPurchaseFailAlert = false
                            purchaseFailScale = 0.3
                        },
                        onCharge: {
                            showPurchaseFailAlert = false
                            purchaseFailScale = 0.3
                            bundleVM.saveCurrentSelection()
                            router.push(.coinCharge)
                        }
                    )
                    .padding(.horizontal, 51)
                }
            }
        }
    }
}
