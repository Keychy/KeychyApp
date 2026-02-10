//
//  Saddle.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import Foundation
import FirebaseFirestore

struct Saddle: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var imageURL: String
    var thumbnailURL: String
    var order: Int?         // 정렬 순서

    enum CodingKeys: String, CodingKey {
        case id
        case imageURL
        case thumbnailURL
        case order
    }
}
