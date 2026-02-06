//
//  MainTabViewModel.swift
//  Keychy
//
//  Created on 12/23/24.
//

import SwiftUI

/// MainTabView의 상태 및 비즈니스 로직 관리
@Observable
class MainTabViewModel {
    // MARK: - Constants
    /// 탭 인덱스
    enum TabIndex: Int {
        case home = 0
        case workshop = 1
        case collection = 2
    }

    /// 화면 전환 시 딜레이 시간
    enum Delay {
        static let splashAnimation: TimeInterval = 0.3
        static let deepLinkCheck: TimeInterval = 0.1
        static let deepLinkChange: TimeInterval = 0.2
        static let sheetPresentation: TimeInterval = 0.5
        static let tabSwitchAnimation: TimeInterval = 0.3
    }

    // MARK: - Properties
    // Tab
    var selectedTab = TabIndex.home.rawValue

    // Routers
    var homeRouter = NavigationRouter<HomeRoute>()
    var collectionRouter = NavigationRouter<CollectionRoute>()
    var workshopRouter = NavigationRouter<WorkshopRoute>()

    // Sheets
    var showReceiveSheet = false
    var showCollectSheet = false
    var receivedPostOfficeId: String?
    var collectedPostOfficeId: String?
    var shouldRefreshCollection = false

    // Splash
    var showSplash = true

    // ViewModels
    let collectionViewModel = CollectionViewModel()
    let bundleViewModel = BundleViewModel()

    // Managers
    let userManager = UserManager.shared
    let deepLinkManager = DeepLinkManager.shared

    // MARK: - Lifecycle Methods
    /// 탭 뷰가 화면에 나타날 때 호출 - 배지 카운트 동기화 및 딥링크 체크
    func handleAppear() {
        userManager.updateBadgeCount()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Delay.deepLinkCheck))
            checkPendingDeepLink()
        }
    }

    /// 딥링크 매니저의 pendingPostOfficeId 변경 감지 시 호출
    func handleDeepLinkChange(_: String?, newValue: String?) {
        if newValue != nil {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Delay.deepLinkChange))
                checkPendingDeepLink()
            }
        }
    }

    // MARK: - Private Methods
    /// 대기 중인 딥링크가 있는지 확인하고 처리
    private func checkPendingDeepLink() {
        if let (postOfficeId, type) = deepLinkManager.consumePendingDeepLink() {
            handleDeepLink(postOfficeId: postOfficeId, type: type)
        }
    }

    /// 딥링크 타입에 따라 적절한 화면으로 라우팅
    /// - Parameters:
    ///   - postOfficeId: 우체국 ID
    ///   - type: 딥링크 타입 (receive, collect, notification)
    private func handleDeepLink(postOfficeId: String, type: DeepLinkType) {
        switch type {
        case .receive:
            handleSheetDeepLink(postOfficeId: postOfficeId, isReceive: true)
        case .collect:
            handleSheetDeepLink(postOfficeId: postOfficeId, isReceive: false)
        case .notification:
            selectedTab = TabIndex.home.rawValue
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Delay.sheetPresentation))
                homeRouter.push(.notificationGiftView(postOfficeId: postOfficeId))
            }
        }
    }

    /// Collection 탭으로 전환하고 받기/모으기 Sheet 표시
    /// - Parameters:
    ///   - postOfficeId: 우체국 ID
    ///   - isReceive: true면 받기 Sheet, false면 모으기 Sheet
    private func handleSheetDeepLink(postOfficeId: String, isReceive: Bool) {
        selectedTab = TabIndex.collection.rawValue

        if isReceive {
            receivedPostOfficeId = postOfficeId
        } else {
            collectedPostOfficeId = postOfficeId
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Delay.sheetPresentation))
            if isReceive {
                showReceiveSheet = true
            } else {
                showCollectSheet = true
            }
        }
    }
}
