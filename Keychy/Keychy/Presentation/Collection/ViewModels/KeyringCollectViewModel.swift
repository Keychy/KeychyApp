//
//  KeyringCollectViewModel.swift
//  Keychy
//
//  Created by Jini on 1/8/26.
//

import SwiftUI
import FirebaseFirestore

@Observable
class KeyringCollectViewModel {
    // MARK: - Properties
    var keyring: Keyring?
    var keyringId: String?
    var senderId: String?
    var senderName: String = ""
    var authorName: String = ""
    var isLoading: Bool = true
    var isAccepting: Bool = false
    var isAccepted: Bool = false
    
    // DeepLink Error
    var hasDeepLinkError: Bool = false
    
    // Alert States
    var showAcceptCompleteAlert: Bool = false
    var showInvenFullAlert: Bool = false
    
    private let collectionViewModel: CollectionViewModel
    private let postOfficeId: String
    
    // MARK: - Init
    init(collectionViewModel: CollectionViewModel, postOfficeId: String, deepLinkError: DeepLinkError? = nil) {
        self.collectionViewModel = collectionViewModel
        self.postOfficeId = postOfficeId
        self.hasDeepLinkError = (deepLinkError != nil)
    }
    
    // MARK: - 데이터 로드
    func loadKeyringData() {
        // DeepLink 에러가 있으면 바로 종료 (errorView로 연결)
        if hasDeepLinkError {
            self.isLoading = false
            return
        }
        
        print("PostOffice 데이터 로드 시작")
        
        collectionViewModel.fetchPostOfficeData(postOfficeId: postOfficeId) { postOfficeData in
            guard let postOfficeData = postOfficeData,
                  let senderId = postOfficeData["senderId"] as? String,
                  let keyringId = postOfficeData["keyringId"] as? String else {
                print("PostOffice 데이터 로드 실패")
                self.isLoading = false
                return
            }

            // 만료 이중 검증 — DeepLinkManager에서 1차 검증 후 여기서 2차 확인
            if let expiresTimestamp = postOfficeData["expiresAt"] as? Timestamp {
                if expiresTimestamp.dateValue() < Date() {
                    print("배포 만료 (2차 검증)")
                    self.hasDeepLinkError = true
                    self.isLoading = false
                    return
                }
            }

            self.senderId = senderId
            self.keyringId = keyringId

            // 키링 정보 가져오기
            self.loadKeyringInfo(keyringId: keyringId, senderId: senderId)
        }
    }
    
    private func loadKeyringInfo(keyringId: String, senderId: String) {
        // keyringId로 키링 정보 가져오기
        collectionViewModel.fetchKeyringById(keyringId: keyringId) { fetchedKeyring in
            guard let keyring = fetchedKeyring else {
                print("키링 로드 실패")
                self.isLoading = false
                return
            }
            
            self.keyring = keyring
            
            // authorId로 제작자 이름 로드
            self.collectionViewModel.fetchUserName(userId: keyring.authorId) { name in
                self.authorName = name
            }
            
            // collect 타입은 Studio 배포이므로 발신자를 "KEYCHY"로 고정
            self.senderName = "KEYCHY"
            self.isLoading = false
        }
    }
    
    // MARK: - 키링 수령 (배포용)
    func acceptKeyring() {
        guard let receiverId = UserDefaults.standard.string(forKey: "userUID"),
              let keyringId = keyringId,
              let senderId = senderId else {
            print("필요한 정보 누락")
            return
        }
        
        collectionViewModel.checkInventoryCapacity(userId: receiverId) { hasSpace in
            if !hasSpace {
                // 보관함 가득 참
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.showInvenFullAlert = true
                }
                return
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self.isAccepting = true
            }
            
            // 배포용 수령 로직
            self.collectionViewModel.collectKeyring(
                keyringId: keyringId,
                senderId: senderId,
                receiverId: receiverId
            ) { success, errorMessage in
                DispatchQueue.main.async {
                    self.isAccepting = false
                    
                    if success {
                        self.handleAcceptSuccess()
                    } else {
                        self.handleAcceptFailure()
                    }
                }
            }
        }
    }
    
    // MARK: - 성공/실패 Handlers
    private func handleAcceptSuccess() {
        self.isAccepted = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self.showAcceptCompleteAlert = true
            }
        }
    }
    
    private func handleAcceptFailure() {
        print("키링 수령 실패")
        /// TODO: 눈에 보이는 동작 추가 필요 (배포 기능 활용할 때가 되면 기획 후 추가할 것)
    }
    
    // MARK: - Helpers
    //  블러 적용 여부
    var shouldApplyBlur: Bool {
        isAccepting ||
        showAcceptCompleteAlert ||
        showInvenFullAlert ||
        false
    }
    
    var shouldShowWhiteBackground: Bool {
        hasDeepLinkError || (!isLoading && (keyring == nil))
    }
}
