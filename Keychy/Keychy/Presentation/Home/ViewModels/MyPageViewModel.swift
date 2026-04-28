//
//  MyPageViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/15/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@Observable
class MyPageViewModel {
    // MARK: - Alert States

    /// 설정 Alert 표시 여부
    var showSettingsAlert = false

    /// Alert 타입
    var alertType: AlertType = .turnOn

    /// 로그아웃 Alert
    var showLogoutAlert = false
    var logoutAlertScale: CGFloat = 0.3

    /// 회원탈퇴 Alert
    var showDeleteAccountAlert = false
    var deleteAccountAlertScale: CGFloat = 0.3

    /// 재인증 필요 Alert
    var showReauthAlert = false

    /// 로딩 Alert
    var showLoadingAlert = false
    var loadingAlertScale: CGFloat = 0.3

    // MARK: - Notification States

    /// 선물 알림 활성화 여부
    var isGiftNotificationEnabled = true

    /// 마케팅 알림 활성화 여부
    var isMarketingNotificationEnabled = false

    // MARK: - Apple Sign In States

    /// Apple Sign In 재인증용 Nonce
    var currentNonce: String?

    /// Apple Auth Coordinator
    var authCoordinator: AppleAuthCoordinator?

    /// Apple Sign In 시트 표시 여부
    var isShowingAppleSignIn = false

    // MARK: - Private Properties

    private let notificationManager = NotificationManager.shared
    private let db = Firestore.firestore()

    // MARK: - Alert Type

    enum AlertType {
        case turnOn

        var title: String {
            switch self {
            case .turnOn:
                return "알림 권한이 필요해요"
            }
        }

        var message: String {
            switch self {
            case .turnOn:
                return "설정에서 알림을 켜주세요"
            }
        }
    }

    // MARK: - Notification Methods

    /// 시스템 알림 권한에 따라 토글 UI 동기화 (Firestore는 건드리지 않음)
    func syncWithSystemPermission(userManager: UserManager) {
        notificationManager.checkPermission { [weak self] isAuthorized in
            guard let self = self else { return }
            if !isAuthorized {
                // 시스템 OFF → 토글 UI만 OFF (Firestore 값은 유지)
                self.isGiftNotificationEnabled = false
                self.isMarketingNotificationEnabled = false
            } else {
                // 시스템 ON → Firestore 값 복원
                self.isGiftNotificationEnabled = userManager.currentUser?.giftNotificationEnabled ?? true
                self.isMarketingNotificationEnabled = userManager.currentUser?.marketingAgreed ?? false
            }
        }
    }

    /// 알림 권한 확보 후 콜백 실행 (notDetermined → 시스템 팝업, denied → 설정 Alert)
    private func ensureNotificationPermission(
        onDeniedRevert: @escaping () -> Void,
        onAuthorized: @escaping () -> Void
    ) {
        notificationManager.getAuthorizationStatus { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .authorized:
                onAuthorized()
            case .notDetermined:
                // 아직 한 번도 안 물어봄 → 시스템 팝업
                self.notificationManager.requestPermission { granted in
                    if granted {
                        onAuthorized()
                    } else {
                        onDeniedRevert()
                    }
                }
            default:
                // denied, provisional 등 → 설정 이동 Alert
                onDeniedRevert()
                self.alertType = .turnOn
                self.showSettingsAlert = true
            }
        }
    }

    /// 선물 알림 토글 변경 처리
    func handleGiftNotificationToggle(newValue: Bool, userManager: UserManager) {
        if newValue {
            ensureNotificationPermission(
                onDeniedRevert: { [weak self] in
                    self?.isGiftNotificationEnabled = false
                },
                onAuthorized: { [weak self] in
                    self?.updateGiftNotification(newValue: true, userManager: userManager)
                }
            )
        } else {
            // 시스템 ON일 때만 Firestore 업데이트 (시스템 OFF면 UI 동기화일 뿐)
            notificationManager.checkPermission { [weak self] isAuthorized in
                guard isAuthorized else { return }
                self?.updateGiftNotification(newValue: false, userManager: userManager)
            }
        }
    }

    /// 선물 알림 Firestore 업데이트
    private func updateGiftNotification(newValue: Bool, userManager: UserManager) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("User")
            .document(uid)
            .updateData(["giftNotificationEnabled": newValue]) { [weak self] error in
                if let error = error {
                    print("선물 알림 설정 저장 실패: \(error.localizedDescription)")
                    DispatchQueue.main.async { [weak self] in
                        self?.isGiftNotificationEnabled = !newValue
                    }
                } else {
                    print("선물 알림 설정 저장 성공: \(newValue)")
                    DispatchQueue.main.async {
                        if var user = userManager.currentUser {
                            user.giftNotificationEnabled = newValue
                            userManager.currentUser = user
                            userManager.saveToCache()
                        }
                    }
                }
            }
    }

    /// 마케팅 정보 알림 토글 변경 처리
    func handleMarketingToggle(newValue: Bool, userManager: UserManager) {
        if newValue {
            ensureNotificationPermission(
                onDeniedRevert: { [weak self] in
                    self?.isMarketingNotificationEnabled = false
                },
                onAuthorized: { [weak self] in
                    self?.updateMarketingNotification(newValue: true, userManager: userManager)
                }
            )
        } else {
            notificationManager.checkPermission { [weak self] isAuthorized in
                guard isAuthorized else { return }
                self?.updateMarketingNotification(newValue: false, userManager: userManager)
            }
        }
    }

    /// 마케팅 알림 Firestore 업데이트
    private func updateMarketingNotification(newValue: Bool, userManager: UserManager) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("User")
            .document(uid)
            .updateData(["marketingAgreed": newValue]) { [weak self] error in
                if let error = error {
                    print("마케팅 알림 설정 저장 실패: \(error.localizedDescription)")
                    DispatchQueue.main.async { [weak self] in
                        self?.isMarketingNotificationEnabled = !newValue
                    }
                } else {
                    print("마케팅 알림 설정 저장 성공: \(newValue)")
                    // Firestore 저장 성공 → 토픽 구독/해제
                    self?.notificationManager.syncKeychyNewsSubscription(marketingAgreed: newValue)
                    DispatchQueue.main.async {
                        if var user = userManager.currentUser {
                            user.marketingAgreed = newValue
                            userManager.currentUser = user
                            userManager.saveToCache()
                        }
                    }
                }
            }
    }

    // MARK: - Logout

    /// 로그아웃
    func logout(userManager: UserManager, introViewModel: IntroViewModel) {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }

        do {
            // 1. keychyNews 토픽 구독 해제
            notificationManager.unsubscribeFromKeychyNews()

            // 2. Firebase Auth 로그아웃
            try Auth.auth().signOut()

            // 3. UserManager 초기화
            userManager.clearUserInfo()

            // 4. 로그인 상태 변경 → RootView가 자동으로 IntroView로 전환
            introViewModel.isLoggedIn = false
            introViewModel.needsProfileSetup = false
        } catch {
            // 로그아웃 실패 처리
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Account

    /// 회원탈퇴 - 항상 재인증 먼저 진행 (데이터 보호)
    func deleteAccount(userManager: UserManager, introViewModel: IntroViewModel) {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }

        guard Auth.auth().currentUser != nil else {
            return
        }

        // 재인증 먼저 진행 (재인증 성공 후에만 데이터 삭제)
        startReauthentication(userManager: userManager, introViewModel: introViewModel)
    }

    /// 재인증 후 회원탈퇴 진행
    func deleteAccountAfterReauth(user: FirebaseAuth.User, userManager: UserManager, introViewModel: IntroViewModel) {
        let uid = user.uid

        // 1. 먼저 Firestore 데이터 삭제 (Auth 유저가 있어야 권한이 있음)
        userManager.deleteUserData(uid: uid) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                // 2. 데이터 삭제 성공 → Firebase Auth 계정 삭제
                user.delete { [weak self] error in
                    guard let self = self else { return }

                    // LoadingAlert 숨기기
                    self.hideLoadingAlert()

                    if let error = error {
                        // Auth 삭제 실패
                        print("회원탈퇴 Auth 삭제 실패: \(error.localizedDescription)")
                        ToastManager.shared.show()
                    } else {
                        // 3. UserManager 초기화 및 로그인 화면으로 이동
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            userManager.clearUserInfo()  // 로컬 캐시 정리
                            introViewModel.isLoggedIn = false
                            introViewModel.needsProfileSetup = false
                        }
                    }
                }

            case .failure:
                // LoadingAlert 숨기기
                self.hideLoadingAlert()
                ToastManager.shared.show()
            }
        }
    }

    // MARK: - Apple Reauthentication

    /// Apple Sign In 재인증
    func startReauthentication(userManager: UserManager, introViewModel: IntroViewModel) {
        let nonce = randomNonceString()
        currentNonce = nonce

        // Apple Sign In 시트 표시 시작 → 네비게이션 바 숨김
        isShowingAppleSignIn = true

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        // Coordinator 생성 및 저장
        let coordinator = AppleAuthCoordinator(
            nonce: nonce,
            onSuccess: { [weak self] credential in
                self?.isShowingAppleSignIn = false
                self?.handleReauthSuccess(credential: credential, userManager: userManager, introViewModel: introViewModel)
            },
            onFailure: { [weak self] error in
                // Apple 재인증 취소 또는 실패 → 네비게이션 바 복원
                self?.isShowingAppleSignIn = false
            }
        )
        authCoordinator = coordinator

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.performRequests()
    }

    /// 재인증 성공 처리
    func handleReauthSuccess(credential: AuthCredential, userManager: UserManager, introViewModel: IntroViewModel) {
        guard let user = Auth.auth().currentUser else {
            return
        }

        // LoadingAlert 표시
        showLoadingAlert = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            loadingAlertScale = 1.0
        }

        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }

            if error != nil {
                // LoadingAlert 숨기기
                self.hideLoadingAlert()
                ToastManager.shared.show()
            } else {
                // 재인증 성공 → 회원탈퇴 진행
                self.deleteAccountAfterReauth(user: user, userManager: userManager, introViewModel: introViewModel)
            }
        }
    }

    // MARK: - Helper Methods

    /// LoadingAlert 숨기기
    private func hideLoadingAlert() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            loadingAlertScale = 0.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showLoadingAlert = false
        }
    }

    // MARK: - Nonce & SHA256 Utilities

    /// 보안용 Nonce 생성
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    /// SHA256 해시
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
