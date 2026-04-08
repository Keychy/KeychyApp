//
//  BundleViewModel+Types.swift
//  Keychy
//
//  Created by 김서현 on 1/9/26.
//

// MARK: - BundleViewModel+Types
//
// 화면 표시용 데이터 구조체
// - BackgroundViewData: 배경 + 소유 여부
// - CarabinerViewData: 카라비너 + 소유 여부
// - KeyringInfo: Firebase 키링 정보

import Foundation

/// 배경 화면 표시용 데이터 (소유 여부 포함)
struct BackgroundViewData: Identifiable, Equatable, Hashable {
    var id: String { background.id ?? UUID().uuidString }
    let background: Background
    let isOwned: Bool
}

/// 카라비너 화면 표시용 데이터 (소유 여부 포함)
struct CarabinerViewData: Identifiable, Equatable, Hashable {
    var id: String { carabiner.id ?? UUID().uuidString }
    let carabiner: Carabiner
    let isOwned: Bool
}

/// Firestore에서 가져온 키링 정보를 담는 구조체
struct KeyringInfo {
    let id: String
    let bodyImage: String
    let selectedTemplate: String?
    let soundId: String
    let particleId: String
    let hookOffsetY: CGFloat?
    let chainLength: Int
    let isGyroscope: Bool
    let shimmerColorId: String?
    let borderColorId: String?
}
