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
    var receivedDeepLinkError: DeepLinkError?
    var collectedDeepLinkError: DeepLinkError?
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
            checkPendingTabDestination()
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

    /// 키치 소식 푸시의 탭 이동 감지 시 호출
    func handleTabDestinationChange(_: String?, newValue: String?) {
        if newValue != nil {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Delay.deepLinkChange))
                checkPendingTabDestination()
            }
        }
    }

    // MARK: - Private Methods
    /// 대기 중인 탭 이동이 있는지 확인하고 처리
    private func checkPendingTabDestination() {
        guard let destination = deepLinkManager.consumePendingTab() else { return }
        switch destination {
        case "홈":
            selectedTab = TabIndex.home.rawValue
        case "공방":
            selectedTab = TabIndex.workshop.rawValue
        case "보관함":
            selectedTab = TabIndex.collection.rawValue
        case "앱스토어":
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6754951347") {
                UIApplication.shared.open(url)
            }
        default:
            selectedTab = TabIndex.home.rawValue
        }
    }

    /// 대기 중인 딥링크가 있는지 확인하고 처리
    private func checkPendingDeepLink() {
        if let (postOfficeId, type, error) = deepLinkManager.consumePendingDeepLink() {
            handleDeepLink(postOfficeId: postOfficeId, type: type, error: error)
        }
    }

    /// 딥링크 타입에 따라 적절한 화면으로 라우팅
    /// - Parameters:
    ///   - postOfficeId: 우체국 ID
    ///   - type: 딥링크 타입 (receive, collect, notification)
    private func handleDeepLink(postOfficeId: String, type: DeepLinkType, error: DeepLinkError?) {
        switch type {
        case .receive:
            handleSheetDeepLink(postOfficeId: postOfficeId, isReceive: true, error: error)
        case .collect:
            handleSheetDeepLink(postOfficeId: postOfficeId, isReceive: false, error: error)
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
    private func handleSheetDeepLink(postOfficeId: String, isReceive: Bool, error: DeepLinkError?) {
        selectedTab = TabIndex.collection.rawValue

        if isReceive {
            receivedPostOfficeId = postOfficeId
            receivedDeepLinkError = error
        } else {
            collectedPostOfficeId = postOfficeId
            collectedDeepLinkError = error
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
