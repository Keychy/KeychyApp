//
//  KeychyUser.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI
import FirebaseFirestore

struct KeychyUser: Identifiable {

    // Firebase Auth UID (Firestore 문서 ID와 동일)
    var id: String
    var nickname: String
    var email: String
    var createdAt: Date
    var maxKeyringCount: Int = 100
    var coin: Int
    var copyVoucher: Int
    var templates: [String]
    var rings: [String]
    var chains: [String]
    var soundEffects: [String]
    var particleEffects: [String]
    var ownedShimmerEffects: [String]  // 구매한 렌티큘러 시머 효과 프리셋 ID 배열
    var ownedBorderEffects: [String]   // 구매한 렌티큘러 테두리 효과 프리셋 ID 배열
    var backgrounds: [String]
    var carabiners: [String]
    var tags: [String]
    var keyrings: [String]
    var recentTemplates: [String] // 최근 사용 템플릿 ID (최대 5개, 최신순)
    var termsAgreed: Bool         // 필수 약관 동의 여부
    var marketingAgreed: Bool     // 마케팅 수신 동의 여부
    var giftNotificationEnabled: Bool  // 선물 알림 수신 여부

    // MARK: - Firestore 변환
    func toDictionary() -> [String: Any] {
        return [
            "nickname": nickname,
            "email": email,
            "createdAt": Timestamp(date: createdAt),
            "maxKeyringCount": maxKeyringCount,
            "coin": coin,
            "copyVoucher": copyVoucher,
            "templates": templates,
            "rings": rings,
            "chains": chains,
            "soundEffects": soundEffects,
            "particleEffects": particleEffects,
            "ownedShimmerEffects": ownedShimmerEffects,
            "ownedBorderEffects": ownedBorderEffects,
            "backgrounds": backgrounds,
            "carabiners": carabiners,
            "tags": tags,
            "keyrings": keyrings,
            "recentTemplates": recentTemplates,
            "termsAgreed": termsAgreed,
            "marketingAgreed": marketingAgreed,
            "giftNotificationEnabled": giftNotificationEnabled
        ]
    }

    // Firestore DocumentSnapshot에서 초기화
    init?(id: String, data: [String: Any]) {
        guard let nickname = data["nickname"] as? String,
              let email = data["email"] as? String,
              let timestamp = data["createdAt"] as? Timestamp else {
            return nil
        }

        self.id = id
        self.nickname = nickname
        self.email = email
        self.createdAt = timestamp.dateValue()
        self.maxKeyringCount = data["maxKeyringCount"] as? Int ?? 100
        self.coin = data["coin"] as? Int ?? 0
        self.copyVoucher = data["copyVoucher"] as? Int ?? 0
        self.templates = data["templates"] as? [String] ?? []
        self.rings = data["rings"] as? [String] ?? []
        self.chains = data["chains"] as? [String] ?? []
        self.soundEffects = data["soundEffects"] as? [String] ?? []
        self.particleEffects = data["particleEffects"] as? [String] ?? []
        self.ownedShimmerEffects = data["ownedShimmerEffects"] as? [String] ?? []
        self.ownedBorderEffects = data["ownedBorderEffects"] as? [String] ?? []
        self.backgrounds = data["backgrounds"] as? [String] ?? []
        self.carabiners = data["carabiners"] as? [String] ?? []
        self.tags = data["tags"] as? [String] ?? []
        self.keyrings = data["keyrings"] as? [String] ?? []
        self.recentTemplates = data["recentTemplates"] as? [String] ?? []
        self.termsAgreed = data["termsAgreed"] as? Bool ?? false
        self.marketingAgreed = data["marketingAgreed"] as? Bool ?? false
        self.giftNotificationEnabled = data["giftNotificationEnabled"] as? Bool ?? true
    }

    // 일반 초기화 (새 유저 생성용)
    init(id: String, nickname: String, email: String) {
        self.id = id
        self.nickname = nickname
        self.email = email
        self.createdAt = Date()
        self.maxKeyringCount = 100
        self.coin = 0
        self.copyVoucher = 5
        self.templates = []
        self.rings = []
        self.chains = []
        self.soundEffects = []
        self.particleEffects = []
        self.ownedShimmerEffects = []
        self.ownedBorderEffects = []
        self.backgrounds = []
        self.carabiners = []
        self.tags = []
        self.keyrings = []
        self.recentTemplates = []
        self.termsAgreed = false
        self.marketingAgreed = false
        self.giftNotificationEnabled = true
    }
}
