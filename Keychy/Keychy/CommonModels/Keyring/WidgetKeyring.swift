//
//  WidgetKeyring.swift
//  Keychy
//
//  Created by Rundo on 11/9/25.
//

import Foundation

/// 위젯에서 사용할 키링 메타데이터
struct WidgetKeyring: Codable, Identifiable, Hashable {
    let id: String          // Firestore documentId
    let name: String        // 키링 이름
    let imagePath: String   // App Group 내 이미지 경로
    let createdAt: Date     // 생성일 (위젯 목록 정렬용)
}
