//
//  HomeRoute.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

/// 홈 탭
enum HomeRoute: Hashable, BundleRoute {
    // Bundle
    case bundleInventoryView
    case bundleDetailView
    case bundleCreateView
    case bundleNameInputView
    case bundleNameEditView
    case bundleEditView
    case bundleCompleteView
    
    // Widget
    case widgetSettingView

    // Home
    case coinCharge
    case myPageView
    case changeName
    case purchaseHistory
    case alarmView
    case notificationGiftView(postOfficeId: String)
    case introView
    case termsAndPolicy

    // Festival
    case festivalView
    case showcase25BoardView
    case festivalKeyringDetailView(Keyring)
}
