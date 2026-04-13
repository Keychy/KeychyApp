//
//  TemplatePreviewComponents.swift
//  Keychy
//
//  Created by Rundo on 11/8/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Template Preview Body
/// 템플릿 프리뷰 body 전체 구조
struct TemplatePreviewBody: View {
    let template: KeyringTemplate?
    let fetchTemplate: () async -> Void
    let onMake: () -> Void
    var onPurchase: (() -> Void)? = nil
    var router: NavigationRouter<WorkshopRoute>? = nil

    @Environment(UserManager.self) private var userManager
    @State private var viewModel = TemplatePreviewViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            if template == nil {
                // fetch 중 — 로딩 인디케이터만 표시
                LoadingAlert(type: .short40, message: nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    // 프리뷰 이미지
                    templatePreview

                    Spacer()

                    VStack(alignment: .leading, spacing: 0) {
                        // 템플릿 정보
                        infoSection
                            .padding(.bottom, 40)
                            .frame(minHeight: 120, alignment: .top)

                        // 액션 버튼
                        actionButton
                            .adaptiveBottomPadding()
                            .padding(.bottom, getBottomPadding(40) == 0 ? 40 : 0)
                    }
                    .padding(.horizontal, 34)

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            CustomNavigationBar {
                BackToolbarButton {
                    TabBarManager.show()
                    router?.pop()
                }
            } center: {
                Spacer()
            } trailing: {
                coinButton
            }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .blur(radius: (viewModel.showPurchasingLoading || viewModel.showPurchaseSuccessAlert) ? 10 : 0)
        .animation(.easeInOut(duration: 0.3), value: (viewModel.showPurchasingLoading || viewModel.showPurchaseSuccessAlert))
        .withToast(position: .button)
        .onAppear {
            TabBarManager.hide()
        }
        .task {
            await fetchTemplate()
        }
        .overlay {
            ZStack(alignment: .center) {
                // 구매 확인 팝업
                if viewModel.showPurchaseSheet {
                    Color.black20
                        .ignoresSafeArea()
                        .onTapGesture {
                            Task { await viewModel.dismissPurchasePopup() }
                        }

                    if let template {
                        PurchasePopup(
                            title: template.name,
                            myCoin: userManager.currentUser?.coin ?? 0,
                            price: template.workshopPrice,
                            scale: viewModel.purchasePopupScale,
                            onConfirm: {
                                Task {
                                    await viewModel.handlePurchase(
                                        template: template,
                                        userManager: userManager
                                    )
                                }
                            }
                        )
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                }

                // 구매 중 로딩
                if viewModel.showPurchasingLoading {
                    LoadingAlert(type: .short40, message: nil)
                }

                // 구매 성공 알림
                if viewModel.showPurchaseSuccessAlert {
                    KeychyAlert(
                        type: .checkmark,
                        message: "구매 완료!",
                        isPresented: $viewModel.showPurchaseSuccessAlert
                    )
                }

                // TODO: - 구버전 Alert 사용중, Popup으로 전환 필요
                // 구매 실패 알림 (코인 부족)
                if viewModel.showPurchaseFailAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {}

                    BangmarkAlert(
                        checkmarkScale: viewModel.purchaseFailScale,
                        text: "코인이 부족해요",
                        cancelText: "취소",
                        confirmText: "충전하기",
                        onCancel: {
                            Task { await viewModel.dismissPurchaseFailAlert() }
                        },
                        onConfirm: {
                            Task {
                                await viewModel.dismissPurchaseFailAlert()
                                router?.push(.coinCharge)
                            }
                        }
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }

                if viewModel.showInvenFullAlert {
                    InvenLackPopup(isPresented: $viewModel.showInvenFullAlert)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - TemplatePreviewBody Extensions
extension TemplatePreviewBody {
    /// 템플릿 프리뷰 이미지
    private var templatePreview: some View {
        VStack {
            Spacer()

            if let template {
                if template.previewImages.count > 1 {
                    TemplateImageSlideshow(
                        imageURLs: template.previewImages,
                        localFirstImageName: "preview_\(template.id ?? "")"
                    )
                        .scaledToFit()
                        .frame(width: 386, height: 386)
                } else if template.previewURL.contains(".gif") {
                    // GIF URL인 경우 애니메이션 재생 (렌티큘러 등)
                    // Firebase Storage URL은 쿼리 파라미터가 붙어 hasSuffix 불가 → contains 사용
                    SimpleAnimatedImage(url: template.previewURL, maxSize: CGSize(width: 400, height: 400))
                        .scaledToFit()
                        .frame(width: 386, height: 386)
                } else {
                    ItemDetailImage(itemURL: template.previewURL)
                        .scaledToFit()
                        .frame(width: 386, height: 386)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
    }

    /// 템플릿 정보 섹션
    private var infoSection: some View {
        Group {
            if let template {
                ItemDetailInfoSection(item: template)
            }
        }
    }

    /// 액션 버튼 (만들기/구매)
    private var actionButton: some View {
        Group {
            if let template {
                TemplateActionButton(
                    template: template,
                    isOwned: viewModel.isOwned(template: template, user: userManager.currentUser),
                    onMake: {
                        viewModel.checkInventoryAndMake(userManager: userManager, onMake: onMake)
                    },
                    onPurchase: onPurchase ?? {
                        viewModel.showPurchasePopup()
                    }
                )
            }
        }
    }

    /// 코인 충전 버튼
    private var coinButton: some View {
        Button {
            router?.push(.coinCharge)
        } label: {
            HStack(spacing: 8) {
                Image(.myCoinMini)

                Text("\((userManager.currentUser?.coin ?? 0).formatted())")
                    .typography(.nanum17EB)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10.5)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
