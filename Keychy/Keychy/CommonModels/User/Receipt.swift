//
//  Receipt.swift
//  Keychy
//
//  Created by 길지훈 on 1/28/26.
//

import Foundation
import FirebaseFirestore

struct Receipt: Identifiable, Codable {
    @DocumentID var id: String?
    var itemID: String
    var itemName: String
    var itemType: String
    var price: Int
    var purchasedAt: Date

    /// 아이템 타입 표시명
    var itemTypeDisplayName: String {
        switch itemType {
        case "template": return "템플릿"
        case "background": return "배경"
        case "carabiner": return "카라비너"
        case "particle": return "파티클"
        case "sound": return "사운드"
        default: return itemType
        }
    }

    /// 구매일시 포맷 (2026-01-01 22:22:22)
    var purchasedAtFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: purchasedAt)
    }
}
