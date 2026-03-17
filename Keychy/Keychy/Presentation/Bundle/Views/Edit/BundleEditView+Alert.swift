//
//  BundleEditView+Alert.swift
//  Keychy
//
//  Created by 김서현 on 1/13/26.
//

import SwiftUI

extension BundleEditView {
    
    // MARK: - Alert Contents
    var alertContent: some View {
        Group {
            // 구매 성공 Alert
            if showPurchaseSuccessAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        Task {
                            await bundleVM.saveBundleChanges()
                            await MainActor.run {
                                showPurchaseSuccessAlert = false
                                purchasesSuccessScale = 0.3
                            }
                        }
                    }
                
                KeychyAlert(type: .checkmark, message: "구매가 완료되었어요!", isPresented: $showPurchaseSuccessAlert)
                    .zIndex(101)
            }
            
            // 구매 실패 Alert
            if showPurchaseFailAlert {
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
    
    // MARK: - 카라비너 캐시 확인
    /// 카라비너의 front/back 이미지가 모두 캐시되어 있는지 확인
    func isCarabinerCached(_ cb: CarabinerViewData) -> Bool {
        [cb.carabiner.backImageURL, cb.carabiner.frontImageURL]
            .compactMap { $0 }
            .allSatisfy { StorageManager.shared.isCached(path: $0) }
    }

    // MARK: - 로딩 오버레이
    var loadingOverlay: some View {
        Group {
            // 최초 진입 로딩
            if !hasInitiallyLoaded && !isNavigatingAway {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(100)
                LoadingAlert(type: .longWithKeychy, message: "키링 뭉치를 불러오고 있어요")
                    .zIndex(101)
            }
            // 아이템 변경 시 캐시 미스 로딩 (최초 로딩 이후에만)
            if hasInitiallyLoaded && (!isSceneReady || isBackgroundLoading) && !isNavigatingAway {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(100)
                LoadingAlert(type: .short40, message: nil)
                    .zIndex(101)
            }
            if isCapturing {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(100)
                LoadingAlert(type: .longWithKeychy, message: "키링 뭉치를 수정하고 있어요")
                    .zIndex(101)
            }
        }
    }
}
