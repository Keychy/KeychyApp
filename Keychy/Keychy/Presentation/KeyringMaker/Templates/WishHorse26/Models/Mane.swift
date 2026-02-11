//
//  Mane.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI
import Foundation
import FirebaseFirestore

struct Mane: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var imageURL: String
    var color: String
    var order: Int?         // 정렬 순서

    enum CodingKeys: String, CodingKey {
        case id
        case imageURL
        case color
        case order
    }
}

enum ManeColorType: String, CaseIterable {
    case gray = "#4D4D4D"
    case darkRed = "#810A15"
    case red = "#FF383C"
    case yellow = "#FDF1BC"
    case pink = "#FFBAE7"
    case purple = "#C2BCFE"
    
    /// SwiftUI Color 반환
    var color: Color {
        Color(hex: self.rawValue)
    }
    
    /// 모든 프리셋 색상 배열
    static var allColors: [Color] {
        allCases.map { $0.color }
    }
    
    /// hex 코드로 ManeColorType 찾기
    static func from(hex: String) -> ManeColorType? {
        let normalizedHex = hex.uppercased()
        return allCases.first { $0.rawValue.uppercased() == normalizedHex }
    }
}
