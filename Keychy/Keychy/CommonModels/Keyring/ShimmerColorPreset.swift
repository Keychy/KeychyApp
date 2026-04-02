//
//  ShimmerColorPreset.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-01.
//

import SwiftUI

// MARK: - 시머 색상 프리셋
/// 렌티큘러 셰이더 스타일 프리셋
/// - mode 0 = 메탈릭, 1 = 홀로그램, 2 = 얼룩, 3 = 펄스, 4 = 모자이크, 5 = 글리터
enum ShimmerColorPreset: String, CaseIterable, Identifiable {
    case silver     // 메탈릭 — 쿨 실버
    case hologram   // 홀로그램 — 순수 무지개
    case liquid     // 얼룩 — 크롬 반사
    case pulse      // 펄스 — 레이더 파동
    case matrix     // 모자이크 — 엠보스 타일
    case cosmos     // 글리터 — 반짝이 알갱이

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .silver:   return "메탈릭"
        case .hologram: return "홀로그램"
        case .liquid:   return "얼룩"
        case .pulse:    return "펄스"
        case .matrix:   return "모자이크"
        case .cosmos:   return "글리터"
        }
    }

    /// 셰이더 mode 값
    var shaderMode: Float {
        switch self {
        case .silver:   return 0.0
        case .hologram: return 1.0
        case .liquid:   return 2.0
        case .pulse:    return 3.0
        case .matrix:   return 4.0
        case .cosmos:   return 5.0
        }
    }

    /// 셰이더에 전달할 틴트 RGB
    var shaderColor: (r: Float, g: Float, b: Float) {
        switch self {
        case .silver:   return (0.82, 0.84, 0.88)
        case .hologram: return (1.0, 1.0, 1.0)
        case .liquid:   return (0.90, 0.92, 0.95)      // 얼룩 크롬 실버
        case .pulse:    return (0.45, 0.55, 0.90)       // 펄스 쿨 블루
        case .matrix:   return (0.0, 0.85, 0.30)        // 모자이크 그린
        case .cosmos:   return (0.08, 0.10, 0.28)        // 글리터 네이비
        }
    }

    /// 셀렉터 UI 미리보기 색상
    var previewColor: UIColor {
        let c = shaderColor
        return UIColor(red: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: 1.0)
    }

    /// 광택 효과 섹션에 표시할 프리셋
    static var shimmerPresets: [ShimmerColorPreset] {
        [.silver, .hologram, .liquid, .matrix]
    }

    /// 테두리 섹션에 표시할 프리셋
    static var borderPresets: [ShimmerColorPreset] {
        [.silver, .hologram, .pulse, .cosmos]
    }
}
