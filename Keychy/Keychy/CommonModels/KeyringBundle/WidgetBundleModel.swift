//
//  WidgetBundleModel.swift
//  Keychy
//
//  Created by 길지훈 on 2/2/26.
//

import Foundation

/// 위젯에서 사용할 뭉치 메타데이터
struct WidgetBundleModel: Codable, Identifiable, Hashable {
    let id: String          // Firestore documentId
    let name: String        // 뭉치 이름
    let imagePath: String   // App Group 내 이미지 경로
    let createdAt: Date     // 생성일 (위젯 목록 정렬용)

    // 기존 데이터 호환용 (createdAt 없는 경우 .distantPast로 처리)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imagePath = try container.decode(String.self, forKey: .imagePath)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
    }

    init(id: String, name: String, imagePath: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.imagePath = imagePath
        self.createdAt = createdAt
    }
}
