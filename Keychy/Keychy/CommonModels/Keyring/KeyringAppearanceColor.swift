//
//  KeyringAppearanceColor.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-01.
//

import SwiftUI

// MARK: - 시머/테두리 색상 통합 모델
/// 프리셋(KeyringStylePreset) + 프리셋 모드를 유지한 커스텀 틴트를 표현
/// - `.preset(.silver)` → 메탈릭 기본색 (mode=0)
/// - `.customTint(mode: .matrix, r, g, b)` → 매트릭스 모드(mode=4) + 커스텀 색상
enum KeyringAppearanceColor: Equatable, Identifiable {
    case preset(KeyringStylePreset)
    case customTint(mode: KeyringStylePreset, r: Float, g: Float, b: Float)

    var id: String { firestoreId }

    // MARK: - 현재 활성 프리셋 (모드 결정용)
    /// `.preset(.matrix)` → `.matrix`, `.customTint(mode: .matrix, ...)` → `.matrix`
    var activePreset: KeyringStylePreset {
        switch self {
        case .preset(let p): return p
        case .customTint(let mode, _, _, _): return mode
        }
    }

    // MARK: - Firestore 저장 ID
    /// 프리셋: "silver", 커스텀 틴트: "silver_D2D6E0"
    var firestoreId: String {
        switch self {
        case .preset(let p): return p.rawValue
        case .customTint(let mode, let r, let g, let b):
            let ir = Int(min(max(r, 0), 1) * 255)
            let ig = Int(min(max(g, 0), 1) * 255)
            let ib = Int(min(max(b, 0), 1) * 255)
            return String(format: "%@_%02X%02X%02X", mode.rawValue, ir, ig, ib)
        }
    }

    // MARK: - Firestore에서 복원
    static func from(id: String?) -> KeyringAppearanceColor {
        guard let id else { return .preset(.silver) }

        // "preset_RRGGBB" 형식 (예: "silver_D2D6E0", "matrix_00D94D")
        for preset in KeyringStylePreset.allCases {
            let prefix = preset.rawValue + "_"
            if id.hasPrefix(prefix) {
                let hex = String(id.dropFirst(prefix.count))
                guard hex.count == 6,
                      let value = UInt32(hex, radix: 16) else { continue }
                let r = Float((value >> 16) & 0xFF) / 255.0
                let g = Float((value >> 8) & 0xFF) / 255.0
                let b = Float(value & 0xFF) / 255.0
                return .customTint(mode: preset, r: r, g: g, b: b)
            }
        }

        // 프리셋 매칭 (정확한 rawValue)
        if let p = KeyringStylePreset(rawValue: id) {
            return .preset(p)
        }

        // 레거시: "custom_RRGGBB" → 메탈릭 틴트로 변환
        if id.hasPrefix("custom_") {
            let hex = String(id.dropFirst(7))
            guard hex.count == 6,
                  let value = UInt32(hex, radix: 16) else {
                return .preset(.silver)
            }
            let r = Float((value >> 16) & 0xFF) / 255.0
            let g = Float((value >> 8) & 0xFF) / 255.0
            let b = Float(value & 0xFF) / 255.0
            return .customTint(mode: .silver, r: r, g: g, b: b)
        }

        // 레거시 하위 호환
        let legacyMap: [String: KeyringStylePreset] = [
            "gold": .silver,
            "roseGold": .silver,
            "goldHolo": .silver,
            "goldDuo": .silver,
            "roseHolo": .silver,
            "roseGlitter": .silver,
            "midnightHolo": .silver,
            "midnightPearl": .silver,
        ]
        if let legacy = legacyMap[id] {
            return .preset(legacy)
        }

        // "glitter_RRGGBB" 레거시 → 메탈릭 틴트로 변환
        if id.hasPrefix("glitter_") {
            let hex = String(id.dropFirst(8))
            guard hex.count == 6,
                  let value = UInt32(hex, radix: 16) else {
                return .preset(.silver)
            }
            let r = Float((value >> 16) & 0xFF) / 255.0
            let g = Float((value >> 8) & 0xFF) / 255.0
            let b = Float(value & 0xFF) / 255.0
            return .customTint(mode: .silver, r: r, g: g, b: b)
        }

        return .preset(.silver)
    }

    // MARK: - 셰이더 Uniform 값
    var shaderColor: (r: Float, g: Float, b: Float) {
        switch self {
        case .preset(let p): return p.shaderColor
        case .customTint(_, let r, let g, let b): return (r, g, b)
        }
    }

    /// 셰이더 mode — 프리셋 모드를 따름 (0=메탈릭, 1=홀로그램, 4=매트릭스, 5=우주)
    var shaderMode: Float {
        activePreset.shaderMode
    }

    // MARK: - UI 미리보기
    var previewColor: UIColor {
        let c = shaderColor
        return UIColor(red: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: 1.0)
    }

    var displayName: String {
        activePreset.displayName
    }

    /// 커스텀 틴트가 적용되었는지 여부
    var isCustomTint: Bool {
        if case .customTint = self { return true }
        return false
    }
}
