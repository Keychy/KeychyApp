//
//  UIViewController+Find.swift
//  Keychy
//
//  Created by 길지훈 on 2/11/26.
//
//  UIViewController 계층에서 특정 컨트롤러 탐색
//

import UIKit

extension UIViewController {

    /// 하위 계층에서 UITabBarController 탐색
    func findTabBarController() -> UITabBarController? {
        if let tabBar = self as? UITabBarController { return tabBar }

        for child in children {
            if let found = child.findTabBarController() { return found }
        }

        return parent?.findTabBarController()
    }

    /// 하위 계층에서 UINavigationController 탐색
    func findNavigationController() -> UINavigationController? {
        if let nav = self as? UINavigationController { return nav }

        for child in children {
            if let found = child.findNavigationController() { return found }
        }

        return nil
    }
}

// MARK: - UIApplication Extension

extension UIApplication {

    /// 현재 활성 윈도우의 rootViewController
    var rootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .rootViewController
    }
}
