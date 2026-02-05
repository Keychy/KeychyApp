//
//  BundleViewModel+Purchase.swift
//  Keychy
//
//  Created by 길지훈 on 2/5/26.
//

// MARK: - BundleViewModel+Purchase
//
// 구매 관련 로직
// - payableItemsCount: 구매 가능 아이템 수
// - totalCartPrice: 총 가격
// - hasUnpurchasedItems: 미구매 아이템 존재 여부
// - purchaseSelectedItems: 구매 처리

import Foundation

extension BundleViewModel {

    // MARK: - Computed Properties

    /// 구매 가능한 아이템 수 (미소유 + 유료)
    var payableItemsCount: Int {
        let backgroundCount = (newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) ? 1 : 0
        let carabinerCount = (newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0) ? 1 : 0
        return backgroundCount + carabinerCount
    }

    /// 총 구매 가격
    var totalCartPrice: Int {
        let backgroundPrice = (newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) ? newSelectedBackground!.background.price : 0
        let carabinerPrice = (newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0) ? newSelectedCarabiner!.carabiner.price : 0
        return backgroundPrice + carabinerPrice
    }

    /// 구매하지 않은 유료 아이템이 있는지 확인
    var hasUnpurchasedItems: Bool {
        let hasUnpurchasedBackground = newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0
        let hasUnpurchasedCarabiner = newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0
        return hasUnpurchasedBackground || hasUnpurchasedCarabiner
    }

    // MARK: - 구매 처리

    /// 선택된 아이템들 구매 처리
    @MainActor
    func purchaseSelectedItems() async -> PurchaseResult {
        isPurchasing = true

        // 선택된 배경이 유료인 경우 구매
        if let bg = newSelectedBackground, !bg.isOwned && bg.background.price > 0 {
            let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(bg.background, userManager: UserManager.shared)

            switch result {
            case .success:
                break
            case .insufficientCoins:
                isPurchasing = false
                return .insufficientCoins
            case .failed(let message):
                isPurchasing = false
                return .failed(message)
            }
        }

        // 선택된 카라비너가 유료인 경우 구매
        if let cb = newSelectedCarabiner, !cb.isOwned && cb.carabiner.price > 0 {
            let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(cb.carabiner, userManager: UserManager.shared)

            switch result {
            case .success:
                break
            case .insufficientCoins:
                isPurchasing = false
                return .insufficientCoins
            case .failed(let message):
                isPurchasing = false
                return .failed(message)
            }
        }

        isPurchasing = false
        return .success
    }
}
