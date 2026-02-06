//
//  HomeTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct HomeTab: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    @Bindable var bundleViewModel: BundleViewModel
    @Bindable var collectionViewModel: CollectionViewModel
    @Binding var selectedTab: Int
    @Bindable private var introViewModel = IntroViewModel()
    @State private var festivalViewModel = Showcase25BoardViewModel()

    /// 배경 로드 완료 콜백
    var onBackgroundLoaded: (() -> Void)? = nil

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(
                router: router,
                userManager: userManager,
                collectionViewModel: collectionViewModel,
                bundleViewModel: bundleViewModel,
                selectedTab: $selectedTab,
                onBackgroundLoaded: onBackgroundLoaded
            )
                .navigationDestination(for: HomeRoute.self) {route in
                    switch route {
                        //키링 뭉치함
                    case .bundleInventoryView:
                        BundleInventoryView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleDetailView:
                        BundleDetailView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleCreateView:
                        BundleCreateView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleNameInputView:
                        BundleNameInputView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleNameEditView:
                        BundleNameEditView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleEditView:
                        BundleEditView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                        // 재화 충전
                    case .coinCharge:
                        CoinChargeView(router: router)
                    case .myPageView:
                        MyPageView(router: router)
                    case .changeName:
                        ChangeNameView(router: router)
                    case .purchaseHistory:
                        PurchaseHistoryView(router: router)
                    case .alarmView:
                        AlarmView(router: router)
                    case .notificationGiftView(let postOfficeId):
                        NotificationGiftView(router: router, collectionViewModel: collectionViewModel, postOfficeId: postOfficeId)
                    case .introView:
                        IntroView(viewModel: introViewModel)
                    case .termsAndPolicy:
                        TermsView(router: router)
                    case .widgetSettingView:
                        WidgetSettingView(router: router)
                    }

                    // Festival
                    case .festivalView:
                        FestivalView(router: router)
                    case .showcase25BoardView:
                        Showcase25BoardView(router: router, viewModel: festivalViewModel)
                    case .festivalKeyringDetailView(let keyring):
                        FestivalKeyringDetailView(router: router, viewModel: festivalViewModel, keyring: keyring)
                }
            }
        }
    }
}
