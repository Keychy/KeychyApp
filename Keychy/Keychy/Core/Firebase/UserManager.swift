//
//  UserManager.swift
//  Keychy
//
//  Created by Jini on 10/28/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import UserNotifications

@Observable
class UserManager {
    static let shared = UserManager()

    /// 유저 모델
    var currentUser: KeychyUser?

    var isLoaded: Bool = false

    /// 알림 목록
    var notifications: [KeychyNotification] = []

    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    private var notificationListener: ListenerRegistration?

    // Apple Sign In 재인증용
    var currentNonce: String?
    var authCoordinator: AppleAuthCoordinator?

    // 편의 접근 프로퍼티
    var userUID: String { currentUser?.id ?? "" }
    var userNickname: String { currentUser?.nickname ?? "" }
    var userEmail: String { currentUser?.email ?? "" }

    /// 읽지 않은 알림이 있는지 여부
    var hasUnreadNotifications: Bool {
        notifications.contains { !$0.isRead }
    }

    private init() {
        loadFromCache()
    }

    // MARK: - Firestore에 프로필 저장
    func saveProfile(user: KeychyUser, completion: @escaping (Bool) -> Void) {
        let userData = user.toDictionary()

        db.collection("User").document(user.id).setData(userData, merge: true) { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }

            if error != nil {
                completion(false)
            } else {
                // 저장 성공 시 로컬 상태 업데이트
                self.currentUser = user
                self.isLoaded = true
                self.saveToCache()
                completion(true)
            }
        }
    }
    
    // MARK: - Firebase에서 프로필 로드
    func loadUserInfo(uid: String, completion: @escaping (Bool) -> Void) {
        db.collection("User").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }

            if error != nil {
                completion(false)
                return
            }

            if let snapshot = snapshot,
               snapshot.exists,
               let data = snapshot.data(),
               let user = KeychyUser(id: uid, data: data) {
                // 프로필 로드 성공
                self.currentUser = user
                self.isLoaded = true
                self.saveToCache()

                // 필드 마이그레이션: 누락된 필드 자동 추가
                self.migrateUserFieldsIfNeeded(user: user)

                // 실시간 리스너 시작
                self.startUserListener(uid: uid)

                completion(true)
            } else {
                // 신규 유저 또는 프로필 미완성
                completion(false)
            }
        }
    }

    // MARK: - 실시간 리스너
    /// Firestore 유저 데이터 실시간 리스너 시작
    private func startUserListener(uid: String) {
        // 기존 리스너 제거
        userListener?.remove()

        userListener = db.collection("User").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if error != nil {
                return
            }

            guard let snapshot = snapshot,
                  snapshot.exists,
                  let data = snapshot.data(),
                  let user = KeychyUser(id: uid, data: data) else {
                return
            }

            // 유저 데이터 업데이트
            self.currentUser = user
            self.saveToCache()
        }
    }

    /// 실시간 리스너 중지
    func stopUserListener() {
        userListener?.remove()
        userListener = nil
    }

    // MARK: - UserDefaults 캐시 관리
    func saveToCache() {
        guard let user = currentUser else { return }

        UserDefaults.standard.set(user.id, forKey: "userUID")
        UserDefaults.standard.set(user.nickname, forKey: "userNickname")
        UserDefaults.standard.set(user.email, forKey: "userEmail")
        UserDefaults.standard.set(user.marketingAgreed, forKey: "userMarketingAgreed")
        UserDefaults.standard.set(user.giftNotificationEnabled, forKey: "userGiftNotificationEnabled")
    }

    private func loadFromCache() {
        let uid = UserDefaults.standard.string(forKey: "userUID") ?? ""
        let nickname = UserDefaults.standard.string(forKey: "userNickname") ?? ""
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let marketingAgreed = UserDefaults.standard.bool(forKey: "userMarketingAgreed")
        // UserDefaults.bool은 키가 없으면 false를 반환하므로, 키 존재 여부로 기본값 분기
        let giftNotificationEnabled = UserDefaults.standard.object(forKey: "userGiftNotificationEnabled") as? Bool ?? true

        if !uid.isEmpty {
            // 캐시에서 임시 유저 생성 (전체 데이터는 Firestore에서 로드 필요)
            var user = KeychyUser(
                id: uid,
                nickname: nickname,
                email: email
            )
            user.marketingAgreed = marketingAgreed
            user.giftNotificationEnabled = giftNotificationEnabled
            currentUser = user
            isLoaded = true
        }
    }

    // MARK: - 필드 마이그레이션
    private func migrateUserFieldsIfNeeded(user: KeychyUser) {
        // merge: true로 누락된 필드만 추가 (기존 데이터는 유지)
        let userData = user.toDictionary()
        db.collection("User").document(user.id).setData(userData, merge: true) { error in
            // 필드 마이그레이션 처리
        }
    }

    // MARK: - 로그아웃
    /// Firebase Auth 로그아웃
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            clearUserInfo()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func clearUserInfo() {
        stopUserListener()
        stopNotificationListener()
        currentUser = nil
        isLoaded = false
        notifications = []

        // UserDefaults 삭제
        UserDefaults.standard.removeObject(forKey: "userNickname")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userUID")
        UserDefaults.standard.removeObject(forKey: "userMarketingAgreed")
        UserDefaults.standard.removeObject(forKey: "userGiftNotificationEnabled")

        // 키링 캐시 전체 삭제
        KeyringImageCache.shared.clearAll()
    }

    // MARK: - 회원탈퇴
    /// Firebase Auth 계정 삭제 (재인증 필요 여부 확인)
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인된 사용자가 없음"])))
            return
        }

        let uid = user.uid

        // 1. 먼저 Firestore 데이터 삭제 (Auth 유저가 있어야 권한이 있음)
        deleteUserData(uid: uid) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case .success:
                // 2. 데이터 삭제 성공 → Firebase Auth 계정 삭제
                user.delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// 재인증 후 회원탈퇴 진행
    func deleteAccountAfterReauth(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인된 사용자가 없음"])))
            return
        }

        let uid = user.uid

        // 1. 먼저 Firestore 데이터 삭제 (Auth 유저가 있어야 권한이 있음)
        deleteUserData(uid: uid) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case .success:
                // 2. 데이터 삭제 성공 → Firebase Auth 계정 삭제
                user.delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Firestore 데이터 삭제
    func deleteUserData(uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 1. User 문서에서 keyrings 배열 가져오기
        db.collection("User").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(.failure(NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserManager instance is nil"])))
                return
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(),
                  let keyringIds = data["keyrings"] as? [String] else {
                // keyrings가 없어도 User 문서는 삭제해야 하므로 계속 진행
                self.deleteUserDocument(uid: uid, completion: completion)
                return
            }

            var deletionError: Error?

            // 2. isPublished가 true인 키링의 ShowcaseFestivalKeyring 초기화 (먼저 실행)
            let showcaseGroup = DispatchGroup()

            print("🔍 회원탈퇴: 키링 개수 \(keyringIds.count)개 확인 중...")

            for keyringId in keyringIds {
                showcaseGroup.enter()
                self.db.collection("Keyring").document(keyringId).getDocument { keyringSnapshot, error in
                    if let error = error {
                        print("⚠️ 키링 문서 조회 실패: \(error.localizedDescription)")
                        showcaseGroup.leave()
                        return
                    }

                    guard let keyringData = keyringSnapshot?.data() else {
                        print("⚠️ 키링 데이터 없음: \(keyringId)")
                        showcaseGroup.leave()
                        return
                    }

                    let isPublished = keyringData["isPublished"] as? Bool ?? false
                    print("🔍 키링 \(keyringId) - isPublished: \(isPublished)")

                    guard isPublished else {
                        // isPublished가 false이거나 없으면 스킵
                        showcaseGroup.leave()
                        return
                    }

                    print("🎯 isPublished true인 키링 발견: \(keyringId)")

                    // isPublished가 true인 경우 ShowcaseFestivalKeyring 초기화
                    self.db.collection("ShowcaseFestivalKeyring")
                        .whereField("keyringId", isEqualTo: keyringId)
                        .getDocuments { querySnapshot, error in
                            if let error = error {
                                print("⚠️ ShowcaseFestivalKeyring 조회 실패: \(error.localizedDescription)")
                                showcaseGroup.leave()
                                return
                            }

                            guard let document = querySnapshot?.documents.first else {
                                // 해당 키링이 쇼케이스에 없으면 스킵
                                print("⚠️ ShowcaseFestivalKeyring에 해당 키링 없음: \(keyringId)")
                                showcaseGroup.leave()
                                return
                            }

                            let showcaseDocId = document.documentID
                            let gridIndex = document.data()["gridIndex"] as? Int ?? 0

                            print("📍 ShowcaseFestivalKeyring 찾음: \(showcaseDocId), gridIndex: \(gridIndex)")

                            // 쇼케이스 필드 초기화
                            let resetData: [String: Any] = [
                                "name": "",
                                "authorId": "",
                                "bodyImageURL": "",
                                "gridIndex": gridIndex,
                                "isEditing": false,
                                "editingUserNickname": "",
                                "keyringId": "none",
                                "memo": "",
                                "particleId": "none",
                                "soundId": "none",
                                "votes": 0
                            ]

                            self.db.collection("ShowcaseFestivalKeyring")
                                .document(showcaseDocId)
                                .setData(resetData) { error in
                                    if let error = error {
                                        print("❌ ShowcaseFestivalKeyring 초기화 실패: \(error.localizedDescription)")
                                        deletionError = error
                                    } else {
                                        print("✅ ShowcaseFestivalKeyring 초기화 완료: \(showcaseDocId)")
                                    }
                                    showcaseGroup.leave()
                                }
                        }
                }
            }

            // 3. ShowcaseFestivalKeyring 초기화 완료 후 키링 삭제 및 Storage 삭제
            showcaseGroup.notify(queue: .main) {
                print("🎉 ShowcaseFestivalKeyring 초기화 단계 완료")

                let deletionGroup = DispatchGroup()

                // Keyring 컬렉션에서 각 키링 문서 삭제
                for keyringId in keyringIds {
                    deletionGroup.enter()
                    self.db.collection("Keyring").document(keyringId).delete { error in
                        if let error = error {
                            print("❌ 키링 삭제 실패: \(keyringId) - \(error.localizedDescription)")
                            deletionError = error
                        } else {
                            print("✅ 키링 삭제 완료: \(keyringId)")
                        }
                        deletionGroup.leave()
                    }
                }

                // Storage에서 사용자 폴더 삭제
                deletionGroup.enter()
                Task {
                    do {
                        try await StorageManager.shared.deleteUserFolder(uid: uid)
                        print("✅ Storage 삭제 완료: \(uid)")
                    } catch {
                        print("❌ Storage 삭제 실패: \(error.localizedDescription)")
                        deletionError = error
                    }
                    deletionGroup.leave()
                }

                // KeyringBundle 컬렉션에서 사용자의 뭉치 삭제
                deletionGroup.enter()
                self.db.collection("KeyringBundle")
                    .whereField("userId", isEqualTo: uid)
                    .getDocuments { querySnapshot, error in
                        if let error = error {
                            print("❌ KeyringBundle 조회 실패: \(error.localizedDescription)")
                            deletionError = error
                            deletionGroup.leave()
                            return
                        }

                        guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                            print("✅ 삭제할 KeyringBundle 없음")
                            deletionGroup.leave()
                            return
                        }

                        let bundleGroup = DispatchGroup()
                        for document in documents {
                            bundleGroup.enter()
                            document.reference.delete { error in
                                if let error = error {
                                    print("❌ KeyringBundle 삭제 실패: \(document.documentID) - \(error.localizedDescription)")
                                    deletionError = error
                                } else {
                                    print("✅ KeyringBundle 삭제 완료: \(document.documentID)")
                                }
                                bundleGroup.leave()
                            }
                        }
                        bundleGroup.notify(queue: .main) {
                            deletionGroup.leave()
                        }
                    }

                // Notifications 컬렉션에서 사용자의 알림 삭제
                deletionGroup.enter()
                self.db.collection("Notifications")
                    .whereField("receiverId", isEqualTo: uid)
                    .getDocuments { querySnapshot, error in
                        if let error = error {
                            print("❌ Notifications 조회 실패: \(error.localizedDescription)")
                            deletionError = error
                            deletionGroup.leave()
                            return
                        }

                        guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                            print("✅ 삭제할 Notifications 없음")
                            deletionGroup.leave()
                            return
                        }

                        let notificationGroup = DispatchGroup()
                        for document in documents {
                            notificationGroup.enter()
                            document.reference.delete { error in
                                if let error = error {
                                    print("❌ Notification 삭제 실패: \(document.documentID) - \(error.localizedDescription)")
                                    deletionError = error
                                } else {
                                    print("✅ Notification 삭제 완료: \(document.documentID)")
                                }
                                notificationGroup.leave()
                            }
                        }
                        notificationGroup.notify(queue: .main) {
                            deletionGroup.leave()
                        }
                    }

                // 4. 모든 삭제 완료 후 User 문서 삭제
                deletionGroup.notify(queue: .main) {
                    print("🎉 모든 데이터 삭제 완료")
                    if let error = deletionError {
                        completion(.failure(error))
                    } else {
                        self.deleteUserDocument(uid: uid, completion: completion)
                    }
                }
            }
        }
    }

    // User 문서 삭제 헬퍼 함수
    private func deleteUserDocument(uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("User").document(uid).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // 로컬 데이터 정리
                self.clearUserInfo()
                completion(.success(()))
            }
        }
    }

    // MARK: - Apple Sign In 재인증
    /// Apple Sign In 재인증 시작
    func startReauthentication(onSuccess: @escaping (AuthCredential) -> Void, onFailure: @escaping (Error) -> Void) {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        // Coordinator 생성 및 저장
        let coordinator = AppleAuthCoordinator(
            nonce: nonce,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
        authCoordinator = coordinator

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.performRequests()
    }

    /// Firebase 재인증
    func reauthenticateWithCredential(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인된 사용자 없음"])))
            return
        }

        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Helper Functions
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

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
    
    // MARK: - 코인 업데이트
    /// 유저의 코인을 증가시키고 Firestore에 저장
    func updateCoin(by amount: Int, completion: @escaping (Bool) -> Void) {
        guard var user = currentUser else {
            print("현재 유저가 없습니다.")
            completion(false)
            return
        }

        // 로컬 상태 업데이트
        user.coin += amount

        // Firestore에 업데이트
        db.collection("User").document(user.id).updateData([
            "coin": user.coin
        ]) { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }

            if let error = error {
                print("코인 업데이트 실패: \(error)")
                completion(false)
            } else {
                // 로컬 상태 반영
                self.currentUser = user
                print("코인 업데이트 성공: \(user.coin)")
                completion(true)
            }
        }
    }

}

// MARK: - AppleAuthCoordinator
class AppleAuthCoordinator: NSObject, ASAuthorizationControllerDelegate {
    private let nonce: String
    private let onSuccess: (AuthCredential) -> Void
    private let onFailure: (Error) -> Void

    init(nonce: String, onSuccess: @escaping (AuthCredential) -> Void, onFailure: @escaping (Error) -> Void) {
        self.nonce = nonce
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        onSuccess(credential)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onFailure(error)
    }
}

// MARK: - Notification Management
extension UserManager {
    /// 알림 실시간 리스너 시작
    func startNotificationListener() {
        guard let userId = currentUser?.id else { return }

        notificationListener = db.collection("Notifications")
            .whereField("receiverId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("[UserManager] 알림 조회 실패: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.notifications = []
                    return
                }

                self.notifications = documents.compactMap { document in
                    KeychyNotification(documentId: document.documentID, data: document.data())
                }
            }
    }

    /// 알림 리스너 중지
    func stopNotificationListener() {
        notificationListener?.remove()
        notificationListener = nil
    }

    /// 앱 아이콘 뱃지를 읽지 않은 알림 개수로 업데이트
    func updateBadgeCount() {
        // 1. 먼저 뱃지를 0으로 초기화 (기존의 잘못된 숫자 제거)
        UNUserNotificationCenter.current().setBadgeCount(0)

        // 2. 읽지 않은 알림 개수를 다시 세서 설정
        let unreadCount = notifications.filter { !$0.isRead }.count
        UNUserNotificationCenter.current().setBadgeCount(unreadCount)

        print("뱃지 업데이트: \(unreadCount)")
    }

    // MARK: - 사용자 데이터 새로고침
    
    /// Firestore에서 최신 사용자 데이터를 가져와 currentUser를 업데이트
    /// - Parameter uid: 사용자 UID
    @MainActor
    func fetchUserData(uid: String) async {
        do {
            let snapshot = try await db.collection("User").document(uid).getDocument()
            
            guard snapshot.exists,
                  let data = snapshot.data(),
                  let user = KeychyUser(id: uid, data: data) else {
                print("사용자 데이터를 찾을 수 없습니다: \(uid)")
                return
            }
            
            // 로컬 상태 업데이트
            self.currentUser = user
            self.saveToCache()
            
            print("UserManager 데이터 새로고침 완료")
            print("   - copyVoucher: \(user.copyVoucher)")
            print("   - coin: \(user.coin)")
            print("   - keyrings count: \(user.keyrings.count)")
            
        } catch {
            print("사용자 데이터 로드 실패: \(error.localizedDescription)")
        }
    }
    
    /// 사용자 데이터 새로고침 (콜백 버전)
    /// - Parameters:
    ///   - uid: 사용자 UID
    ///   - completion: 완료 콜백 (성공 여부)
    func fetchUserData(uid: String, completion: @escaping (Bool) -> Void) {
        db.collection("User").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("사용자 데이터 로드 실패: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let snapshot = snapshot,
                  snapshot.exists,
                  let data = snapshot.data(),
                  let user = KeychyUser(id: uid, data: data) else {
                print("사용자 데이터를 찾을 수 없습니다: \(uid)")
                completion(false)
                return
            }
            
            // 로컬 상태 업데이트
            self.currentUser = user
            self.saveToCache()
            
            print("UserManager 데이터 새로고침 완료")
            print("   - copyVoucher: \(user.copyVoucher)")
            print("   - coin: \(user.coin)")
            print("   - keyrings count: \(user.keyrings.count)")
            
            completion(true)
        }
    }
}
