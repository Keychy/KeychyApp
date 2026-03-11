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
            if showChangeCarabinerAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showChangeCarabinerAlert = false
                        }
                    }
                VStack {
                    Spacer()
                    CarabinerPopup(
                        title: "카라비너를 변경하시겠어요?",
                        message: "새 카라비너로 변경하면\n현재 뭉치에 걸린 키링들이 모두 해제돼요.",
                        onCancel: {
                            selectCarabiner = nil
                            showChangeCarabinerAlert = false
                        },
                        onConfirm: {
                            Task { @MainActor in
                                // 편집 중 로컬 상태만 변경 (Firestore에 쓰지 않음)
                                
                                // 1) UI 오버레이/선택 상태 초기화
                                selectedPosition = 0
                                
                                // 2) 키링 데이터와 선택 목록을 즉시 비우기
                                keyringDataList = []
                                bundleVM.selectedKeyrings.removeAll()
                                bundleVM.keyringOrder.removeAll()
                                
                                // 3) 새 카라비너 적용 (정적 + 캐시 미스일 때만 로딩 표시)
                                if let cb = selectCarabiner, !cb.carabiner.isLottie, !isCarabinerCached(cb) {
                                    isSceneReady = false
                                }
                                bundleVM.newSelectedCarabiner = selectCarabiner
                                
                                // 4) 빈 상태를 씬/리스트에 반영
                                updateKeyringDataList()
                                
                                // 5) 씬 강제 리프레시로 남은 잔상 제거
                                sceneRefreshId = UUID()
                                
                                // 6) 알럿 닫기
                                showChangeCarabinerAlert = false
                            }
                        }
                    )
                    .padding(.horizontal, 51)
                    Spacer()
                }
            }
            
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
    private func isCarabinerCached(_ cb: CarabinerViewData) -> Bool {
        [cb.carabiner.backImageURL, cb.carabiner.frontImageURL]
            .compactMap { $0 }
            .allSatisfy { StorageManager.shared.isCached(path: $0) }
    }

    // MARK: - 로딩 오버레이
    var loadingOverlay: some View {
        Group {
            // 첫 진입 : 씬 준비 + 사용자 보유 키링 로딩 + 배경 다운로드가 모두 끝나야 사라짐
            if (!isSceneReady || isKeyringSheetLoading || isBackgroundLoading) && !isNavigatingAway {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(100)
                LoadingAlert(type: .longWithKeychy, message: "키링 뭉치를 불러오고 있어요")
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
