//
//  NotificationManager.swift
//  Keychy
//
//  Created by gil on 11/9/25.
//

import SwiftUI
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

@Observable
class NotificationManager: NSObject {
    static let shared = NotificationManager()

    /// 알림 권한 상태
    var isAuthorized: Bool = false

    private override init() {
        super.init()
        // 초기화 시 권한 체크
        checkPermission { _ in }
    }

    // MARK: - 알림 권한 체크
    /// 현재 알림 권한 상태를 확인
    func checkPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                let authorized = settings.authorizationStatus == .authorized
                self?.isAuthorized = authorized
                completion(authorized)
            }
        }
    }

    /// 알림 권한 상태를 상세하게 확인 (notDetermined, denied, authorized 등 구분)
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - 알림 권한 요청
    /// 알림 권한 요청 (처음 요청 시에만 시스템 팝업 표시)
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion(granted)
            }
        }
    }

    // MARK: - 설정 앱 열기
    /// iOS 설정 앱의 해당 앱 설정 화면으로 이동
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - FCM 토큰 설정
    /// FCM 토큰을 받아서 Firestore User 문서에 저장
    func setupFCMToken(userId: String) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("[FCM] 토큰 가져오기 실패: \(error.localizedDescription)")
                return
            }

            guard let token = token else {
                print("[FCM] 토큰이 없습니다")
                return
            }

            print("[FCM] 토큰 받음: \(token)")

            // Firestore User 문서에 저장
            Firestore.firestore()
                .collection("User")
                .document(userId)
                .updateData(["fcmToken": token]) { error in
                    if let error = error {
                        print("[FCM] Firestore 저장 실패: \(error.localizedDescription)")
                    } else {
                        print("[FCM] Firestore 저장 완료")
                    }
                }
        }
    }

    // MARK: - FCM 토픽 구독 관리

    /// keychyNews 토픽 구독 (마케팅 알림 수신 동의 시)
    func subscribeToKeychyNews() {
        Messaging.messaging().subscribe(toTopic: "keychyNews") { error in
            if let error = error {
                print("[FCM] keychyNews 토픽 구독 실패: \(error.localizedDescription)")
            } else {
                print("[FCM] keychyNews 토픽 구독 성공")
            }
        }
    }

    /// keychyNews 토픽 구독 해제 (마케팅 알림 수신 거부 시)
    func unsubscribeFromKeychyNews() {
        Messaging.messaging().unsubscribe(fromTopic: "keychyNews") { error in
            if let error = error {
                print("[FCM] keychyNews 토픽 구독 해제 실패: \(error.localizedDescription)")
            } else {
                print("[FCM] keychyNews 토픽 구독 해제 성공")
            }
        }
    }

    /// marketingAgreed 값에 따라 토픽 구독 상태 동기화
    func syncKeychyNewsSubscription(marketingAgreed: Bool) {
        if marketingAgreed {
            subscribeToKeychyNews()
        } else {
            unsubscribeFromKeychyNews()
        }
    }

    // MARK: - FCM 토큰 갱신 처리
    /// 토큰이 갱신될 때마다 호출 (MessagingDelegate에서 사용)
    func updateFCMToken(_ token: String, userId: String) {
        Firestore.firestore()
            .collection("User")
            .document(userId)
            .updateData(["fcmToken": token]) { error in
                if let error = error {
                    print("[FCM] 토큰 갱신 실패: \(error.localizedDescription)")
                }
            }
    }
}
