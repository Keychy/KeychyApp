//
//  DeepLinkManager.swift
//  Keychy
//
//  Created by Jini on 11/8/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

enum DeepLinkType {
    case receive      // 1:1 선물
    case collect      // 배포용
    case notification // 푸시 알림
}

enum DeepLinkError {
    case notFound           // 존재하지 않는 링크
    case missingType        // type 필드 없음
    case typeMismatch       // URL 타입과 문서 타입 불일치
}

@Observable
class DeepLinkManager {
    static let shared = DeepLinkManager()
    
    var pendingPostOfficeId: String?
    var pendingDeepLinkType: DeepLinkType?
    var pendingError: DeepLinkError?

    // 키치 소식 푸시 알림 → 탭 이동용
    var pendingTabDestination: String?
    
    private init() {}
    
    private let db = Firestore.firestore()
    
    func handleDeepLink(postOfficeId: String, type: DeepLinkType) {
        print("딥링크 저장: \(postOfficeId), 타입: \(type)")
        
        // 1. Firestore에서 PostOffice 조회
        db.collection("PostOffice").document(postOfficeId).getDocument { snapshot, error in
            // 문서가 존재하지 않거나 에러 발생
            guard error == nil, let data = snapshot?.data() else {
                print("존재하지 않는 링크입니다")
                DispatchQueue.main.async {
                    self.pendingPostOfficeId = postOfficeId
                    self.pendingDeepLinkType = type
                    self.pendingError = .notFound
                }
                return
            }
            
            // 2. type 필드 확인
            guard let documentTypeString = data["type"] as? String,
                  let documentType = PostOfficeType(rawValue: documentTypeString) else {
                print("type 필드 없음")
                DispatchQueue.main.async {
                    self.pendingPostOfficeId = postOfficeId
                    self.pendingDeepLinkType = type
                    self.pendingError = .missingType
                }
                return
            }
            
            // 3. URL 타입과 문서 타입 비교
            let isValid = self.validateLinkType(urlType: type, documentType: documentType)
            
            guard isValid else {
                print("타입 불일치 - URL: \(type), Document: \(documentType)")
                DispatchQueue.main.async {
                    self.pendingPostOfficeId = postOfficeId
                    self.pendingDeepLinkType = type
                    self.pendingError = .typeMismatch
                }
                return
            }
            
            // 4. 검증 통과 → 정상 처리
            DispatchQueue.main.async {
                self.pendingPostOfficeId = postOfficeId
                self.pendingDeepLinkType = type
                self.pendingError = nil
            }
        }
    }
    
    // 키치 소식 푸시 → 탭 이동 처리
    func handleNewsPush(destination: String) {
        DispatchQueue.main.async {
            self.pendingTabDestination = destination
        }
    }

    // 탭 이동 대기열 소비 (한 번만 사용)
    func consumePendingTab() -> String? {
        guard let destination = pendingTabDestination else { return nil }
        pendingTabDestination = nil
        return destination
    }

    func consumePendingDeepLink() -> (postOfficeId: String, type: DeepLinkType, error: DeepLinkError?)? {
        guard let postOfficeId = pendingPostOfficeId,
              let type = pendingDeepLinkType else {
            return nil
        }
        
        let error = pendingError
        
        self.pendingPostOfficeId = nil
        self.pendingDeepLinkType = nil
        self.pendingError = nil
        
        return (postOfficeId, type, error)
    }
    
    static func createTestReceiveLink(postOfficeId: String) -> URL? {
        return URL(string: "keychy://receive?postOfficeId=\(postOfficeId)")
    }
    
    static func createTestCollectLink(postOfficeId: String) -> URL? {
        return URL(string: "keychy://collect?postOfficeId=\(postOfficeId)")
    }
    
    // 배포용 Universal Link - Receive (1:1 선물)
    static func createUniversalReceiveLink(postOfficeId: String) -> URL? {
        return URL(string: "https://keychy-f6011.web.app/receive/\(postOfficeId)")
    }
    
    // 배포용 Universal Link - Collect (배포)
    static func createUniversalCollectLink(postOfficeId: String) -> URL? {
        return URL(string: "https://keychy-f6011.web.app/collect/\(postOfficeId)")
    }
    
    // 환경에 따라 자동 선택
    static func createShareLink(postOfficeId: String) -> URL? {
        //return createTestLink(keyringId: keyringId)
        return createUniversalReceiveLink(postOfficeId: postOfficeId)
    }
    
    // URL 타입과 PostOffice 타입 일치여부 검사
    private func validateLinkType(urlType: DeepLinkType, documentType: PostOfficeType) -> Bool {
        switch urlType {
        case .receive: return documentType == .receive
        case .collect: return documentType == .collect
        case .notification: return true
        }
    }
}
