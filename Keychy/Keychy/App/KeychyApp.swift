//
//  KeychyApp.swift
//  Keychy
//
//  Created by 길지훈 on 10/26/25.
//

import SwiftUI
import Nuke

/// Keychy 앱의 진입점
/// - AppDelegate를 통해 Firebase, Push 알림 등의 초기 설정 수행
/// - DeepLinkHandler를 통해 Custom URL Scheme 및 Universal Link 처리
@main
struct KeychyApp: App {
    // MARK: - Properties
    /// AppDelegate 연결: Firebase 초기화, 푸시 알림 설정, TabBar 스타일 설정 등을 처리
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Nuke DataCache 활성화 (HTTP 헤더 무시, 무조건 디스크 저장)
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)

        // 기존 StorageManager 디스크 캐시 → Nuke DataCache 마이그레이션 (1회성)
        let migrationKey = "didMigrateToNukeDataCache"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            let oldCacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("StorageImageCache")
            try? FileManager.default.removeItem(at: oldCacheDir)
            UserDefaults.standard.set(true, forKey: migrationKey)
        }

        // 네트워크 모니터링 시작
        NetworkManager.shared.startMonitoring()

        // 키링 캐시 스케일 버전 체크 (KeyringScale 적용으로 인한 재캡처)
        KeyringImageCache.shared.invalidateCacheIfScaleVersionChanged()

        // 위젯 자동 등록 → 수동 등록 전환 마이그레이션
        KeyringImageCache.shared.migrateToManualWidgetSelectionIfNeeded()
    }
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            RootView()
                // 다크모드 미지원 - 추후 디자인시스템 추가될 예정
                .preferredColorScheme(.light)
            
                // Universal Link
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        DeepLinkHandler.shared.handle(url)
                    }
                }
        
                // Custom URL Scheme
                .onOpenURL { url in
                    DeepLinkHandler.shared.handle(url)
                }
        }
    }
}
