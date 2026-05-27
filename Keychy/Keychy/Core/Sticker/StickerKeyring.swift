//
//  StickerKeyring.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-22.
//

import Foundation

/// 스티커 생성에 필요한 키링 메타데이터 (Firebase 의존성 없음)
///
/// 메인 앱이 `sticker_keyrings.json`에 저장하고,
/// iMessage Extension이 읽어서 온디맨드 APNG를 생성한다.
/// `Keyring` 모델과 달리 Firestore/SwiftUI 임포트가 없어
/// Extension 타겟에도 안전하게 포함할 수 있다.
struct StickerKeyring: Codable {
    let id: String
    let name: String
    let bodyImageURL: String
    let chainLength: Int
    let selectedTemplate: String
    let isGyroscope: Bool
    let createdAt: Date
}

/// 메인 앱·위젯·iMessage Extension 등 모든 타겟이 공유하는 App Group 식별자
///
/// 스티커 전용이 아니라 전체 공유 컨테이너 식별자이므로 중립적인 이름을 사용한다.
enum AppGroup {
    static let id = "group.keychy.app"
}
