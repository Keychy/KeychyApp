//
//  TabBarManager.swift
//  Keychy
//
//  Created by 길지훈 on 2/11/26.
//
//  탭바 표시/숨김을 관리하는 매니저
//  - show(): 탭바 표시 (애니메이션)
//  - hide(): 탭바 숨김 + 스와이프 백 제스처 연동 설정
//  - setAlpha(): 탭바 투명도 직접 설정
//

import UIKit

enum TabBarManager {

    // MARK: - Tab Index

    enum Tab: Int {
        case home = 0
        case workshop = 1
        case collection = 2
        case festival = 3
    }

    // MARK: - Public Methods

    /// 탭바 표시 (fade in 애니메이션)
    static func show() {
        animate(toAlpha: 1.0)
    }

    /// 탭바 숨김 (fade out) + 스와이프 백 제스처 연동
    static func hide() {
        animate(toAlpha: 0.0)
        setupSwipeGestureObserver()
    }

    /// 탭바 투명도 직접 설정 (애니메이션 없음)
    static func setAlpha(_ alpha: CGFloat) {
        tabBar?.alpha = alpha
    }

    /// 특정 탭으로 전환
    static func switchTo(_ tab: Tab) {
        tabBarController?.selectedIndex = tab.rawValue
    }

    // MARK: - Private 변/함

    private static var tabBarController: UITabBarController? {
        UIApplication.shared.rootViewController?.findTabBarController()
    }

    private static var tabBar: UITabBar? {
        tabBarController?.tabBar
    }

    private static func animate(toAlpha alpha: CGFloat) {
        UIView.animate(withDuration: alpha > 0 ? 0.25 : 0.2) {
            tabBar?.alpha = alpha
        }
    }

    private static func setupSwipeGestureObserver() {
        guard let selectedVC = tabBarController?.selectedViewController,
              let navController = selectedVC.findNavigationController(),
              let gesture = navController.interactivePopGestureRecognizer else { return }

        TabBarSwipeObserver.shared.attach(to: gesture)
    }
}
