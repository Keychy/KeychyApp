//
//  BundleViewModel+Helpers.swift
//  Keychy
//
//  Created by 길지훈 on 2/5/26.
//

// MARK: - BundleViewModel+Helpers
//
// 유틸리티 메서드
// - resolveBackground/Carabiner: ID → 모델 변환
// - makeBackgroundId/CarabinerId/KeyringsId: 구성 ID 생성

import Foundation

extension BundleViewModel {

    // MARK: - ID → Model 변환

    func resolveBackground(from id: String) -> Background? {
        backgrounds.first { $0.id == id }
    }

    func resolveCarabiner(from id: String) -> Carabiner? {
        carabiners.first { $0.id == id }
    }

    // MARK: - 구성 ID 생성 (씬 리로드 판단용)

    func makeBackgroundId(_ bg: Background?) -> String {
        guard let bg else { return "" }
        return bg.id ?? ""
    }

    func makeCarabinerId(_ cb: Carabiner?) -> String {
        guard let cb else { return "" }
        return "\(cb.id ?? "")|\(cb.carabinerX)|\(cb.carabinerY)|\(cb.carabinerWidth)"
    }

    func makeKeyringsId(_ list: [MultiKeyringScene.KeyringData]) -> String {
        list
            .sorted(by: { $0.index < $1.index })
            .map { item in
                "\(item.index)|\(item.bodyImageURL)|\((item.templateId ?? ""))|\(item.soundId)|\(item.particleId)|\((item.hookOffsetY ?? 0))|\(item.chainLength)"
            }
            .joined(separator: ";")
    }

}
