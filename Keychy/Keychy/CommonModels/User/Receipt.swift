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
    
}
