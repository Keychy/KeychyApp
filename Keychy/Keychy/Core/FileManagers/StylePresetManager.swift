//
//  StylePresetManager.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-09.
//
//  렌티큘러 스타일 프리셋(시머/테두리)의 가격 로드 + 소유 여부 관리
//  - EffectManager.isOwned(soundId:) / (particleId:) 패턴을 미러링
//  - 가격은 Firestore의 Template/Lenticular 하위 서브컬렉션에서 로드
//    (ShimmerEffects / BorderEffects)
//  - 로드 실패 시 KeyringStylePreset.defaultPrice(in:) fallback 사용
//

import Foundation
import FirebaseFirestore

@MainActor
@Observable
final class StylePresetManager {
    static let shared = StylePresetManager()

    /// 시머 프리셋 ID → 가격
    private var shimmerPrices: [String: Int] = [:]
    /// 테두리 프리셋 ID → 가격
    private var borderPrices: [String: Int] = [:]

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - 가격 로드
    /// 앱 시작 시 한 번 호출하여 Firestore에서 가격 정보를 메모리에 적재
    /// 경로: `Template/Lenticular/ShimmerEffects`, `Template/Lenticular/BorderEffects`
    func loadPrices() async {
        let lenticularDoc = db.collection("Template").document("Lenticular")

        do {
            // 시머 가격
            let shimmerSnap = try await lenticularDoc.collection("ShimmerEffects").getDocuments()
            shimmerPrices = Dictionary(uniqueKeysWithValues: shimmerSnap.documents.compactMap {
                guard let price = $0.data()["price"] as? Int else { return nil }
                return ($0.documentID, price)
            })

            // 테두리 가격
            let borderSnap = try await lenticularDoc.collection("BorderEffects").getDocuments()
            borderPrices = Dictionary(uniqueKeysWithValues: borderSnap.documents.compactMap {
                guard let price = $0.data()["price"] as? Int else { return nil }
                return ($0.documentID, price)
            })
        } catch {
            // 실패 시 빈 dict 유지 → defaultPrice fallback이 작동
        }
    }

    // MARK: - 가격 조회
    /// 프리셋 가격 조회 (Firestore → fallback 순서)
    func price(for preset: KeyringStylePreset, in section: StyleSection) -> Int {
        if preset.isFree { return 0 }
        let firestoreValue = (section == .shimmer ? shimmerPrices : borderPrices)[preset.rawValue]
        return firestoreValue ?? preset.defaultPrice(in: section)
    }

    // MARK: - 소유 여부
    /// 무료 프리셋(silver)은 owned 배열에 없어도 사용 가능 → 별도 isFree 분기 필요
    /// (EffectManager.isOwned 패턴과 동일하게 무료/소유 검사를 분리)
    func isOwned(preset: KeyringStylePreset, in section: StyleSection, userManager: UserManager) -> Bool {
        guard let user = userManager.currentUser else { return false }
        let owned = section == .shimmer ? user.ownedShimmerEffects : user.ownedBorderEffects
        return owned.contains(preset.rawValue)
    }
}
