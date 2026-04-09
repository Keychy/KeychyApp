//
//  EffectItem.swift
//  Keychy
//
//  키링 커스터마이징 화면에서 카트에 담기는 아이템
//

import Foundation

/// 장바구니에 담기는 이펙트 아이템
/// - 사운드 / 파티클 / 렌티큘러 시머 / 렌티큘러 테두리 모두 표현 가능
struct EffectItem: Identifiable, Equatable {
    let id: String
    let name: String
    let type: EffectType
    let price: Int
    let thumbnailURL: String

    /// SwiftUI ForEach 등에서 안전하게 식별할 수 있는 합성 키
    /// - `id`만 쓰면 시머 hologram(id="hologram")과 테두리 hologram(id="hologram")이
    ///   같은 식별자가 되어 ForEach가 중복 제거해버린다.
    /// - type을 prefix로 붙여 (시머 hologram) ≠ (테두리 hologram) 보장.
    var uniqueId: String {
        "\(type.rawValue)_\(id)"
    }

    /// Sound 모델에서 EffectItem 생성
    init(sound: Sound) {
        self.id = sound.id ?? ""
        self.name = sound.soundName
        self.type = .sound
        self.price = sound.price
        self.thumbnailURL = sound.thumbnail
    }

    /// Particle 모델에서 EffectItem 생성
    init(particle: Particle) {
        self.id = particle.id ?? ""
        self.name = particle.particleName
        self.type = .particle
        self.price = particle.price
        self.thumbnailURL = particle.thumbnail
    }

    /// 렌티큘러 시머 효과 프리셋에서 EffectItem 생성
    init(shimmerEffect preset: KeyringStylePreset, price: Int) {
        self.id = preset.rawValue
        self.name = preset.displayName
        self.type = .shimmerEffect
        self.price = price
        self.thumbnailURL = ""
    }

    /// 렌티큘러 테두리 효과 프리셋에서 EffectItem 생성
    init(borderEffect preset: KeyringStylePreset, price: Int) {
        self.id = preset.rawValue
        self.name = preset.displayName
        self.type = .borderEffect
        self.price = price
        self.thumbnailURL = ""
    }
}

/// 이펙트 타입 (Receipt itemType으로도 사용됨)
enum EffectType: String {
    case sound = "사운드"
    case particle = "파티클"
    case shimmerEffect = "렌티큘러 광택"
    case borderEffect = "렌티큘러 테두리"
}
