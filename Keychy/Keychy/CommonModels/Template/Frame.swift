//
//  Frame.swift
//  Keychy
//
//  폴라로이드 프레임 모델
//

import Foundation
import FirebaseFirestore

struct Frame: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var frameURL: String
    var name: String
    var thumbnailURL: String
    var type: String?       // SpeechBubble 프레임 타입 (A, B, C)
    var order: Int?         // 정렬 순서
    var textOffsetY: CGFloat?  // SpeechBubble 텍스트 Y 오프셋
    var checkerBoardURL: String? // DuZzonKu 프레임에 맞는 체커보드
    var checkerBoardRects: [CheckerBoardRect]?

    // 유니폼 전용
    var numberOffsetY: CGFloat?     // 등번호 Y 오프셋
    var nameOffsetY: CGFloat?       // 이름 Y 오프셋
    var numberFontSize: CGFloat?    // 등번호 폰트 크기
    var nameFontSize: CGFloat?      // 이름 폰트 크기

    // 가격 (유료/무료 프레임 구분)
    var price: Int?                 // 0 = 무료, nil = 무료, 양수 = 유료

    enum CodingKeys: String, CodingKey {
        case id
        case frameURL
        case name
        case thumbnailURL
        case type
        case order
        case textOffsetY
        case checkerBoardURL
        case checkerBoardRects
        case numberOffsetY
        case nameOffsetY
        case numberFontSize
        case nameFontSize
        case price
    }
}
