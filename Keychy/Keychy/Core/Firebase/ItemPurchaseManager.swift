//
//  ItemPurchaseManager.swift
//  Keychy
//
//  아이템 구매 처리 로직 (워크샵, 코인샵 등)
//

import Foundation
import FirebaseFirestore

// MARK: - Purchase Result
enum PurchaseResult {
    case success
    case insufficientCoins
    case failed(String)
}

enum ItemPurchaseError: Error {
    case insufficientCoins
    case userNotFound
    case itemNotFound
    case updateFailed

    var localizedDescription: String {
        switch self {
        case .insufficientCoins:
            return "코인이 부족합니다"
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다"
        case .itemNotFound:
            return "아이템 정보를 찾을 수 없습니다"
        case .updateFailed:
            return "구매 처리 중 오류가 발생했습니다"
        }
    }
}

@MainActor
class ItemPurchaseManager {
    static let shared = ItemPurchaseManager()

    private init() {}

    // MARK: - Public Methods
    /// 워크샵 아이템 구매 처리
    func purchaseWorkshopItem(_ item: any WorkshopItem, userManager: UserManager) async -> PurchaseResult {
        // 1. 유저/아이템 정보 검증
        guard let purchaseInfo = validatePurchaseInfo(item: item, userManager: userManager) else {
            return .failed("사용자 정보를 찾을 수 없습니다")
        }

        // 2. 로컬 코인 확인
        guard purchaseInfo.userCoins >= item.workshopPrice else {
            return .insufficientCoins
        }

        // 3. Firebase 구매 처리
        let userRef = Firestore.firestore().collection("User").document(purchaseInfo.userId)

        do {
            // 서버 코인 확인 & 업데이트
            let currentCoin = try await fetchCurrentCoin(userRef: userRef)
            guard currentCoin >= item.workshopPrice else {
                return .insufficientCoins
            }

            // 코인 차감 & 아이템 추가
            let updateData = buildUpdateData(item: item, itemId: purchaseInfo.itemId, currentCoin: currentCoin)
            try await userRef.updateData(updateData)

            // 구매내역 저장
            try await saveReceipt(item: item, itemId: purchaseInfo.itemId, userRef: userRef)

            // UserManager 갱신
            await refreshUserData(userId: purchaseInfo.userId, userManager: userManager)

            return .success

        } catch {
            print("구매 실패: \(error.localizedDescription)")
            return .failed("구매 처리 중 오류가 발생했습니다")
        }
    }

    // MARK: - Private Methods
    /// 구매에 필요한 정보 검증
    private func validatePurchaseInfo(
        item: any WorkshopItem,
        userManager: UserManager
    ) -> (userId: String, userCoins: Int, itemId: String)? {
        guard let userId = userManager.currentUser?.id,
              let userCoins = userManager.currentUser?.coin,
              let itemId = item.id else {
            return nil
        }
        return (userId, userCoins, itemId)
    }

    /// 서버에서 현재 코인 조회
    private func fetchCurrentCoin(userRef: DocumentReference) async throws -> Int {
        let snapshot = try await userRef.getDocument()
        guard let data = snapshot.data() else {
            throw ItemPurchaseError.userNotFound
        }
        return data["coin"] as? Int ?? 0
    }

    /// 업데이트 데이터 생성 (코인 차감 + 아이템 추가)
    private func buildUpdateData(
        item: any WorkshopItem,
        itemId: String,
        currentCoin: Int
    ) -> [String: Any] {
        var updateData: [String: Any] = [
            "coin": currentCoin - item.workshopPrice
        ]

        let fieldName = itemFieldName(for: item)
        updateData[fieldName] = FieldValue.arrayUnion([itemId])

        return updateData
    }

    /// 아이템 타입에 해당하는 Firestore 필드명
    private func itemFieldName(for item: any WorkshopItem) -> String {
        switch item {
        case is KeyringTemplate: return "templates"
        case is Background: return "backgrounds"
        case is Carabiner: return "carabiners"
        case is Particle: return "particleEffects"
        case is Sound: return "soundEffects"
        default: return "unknown"
        }
    }

    /// 아이템 타입 문자열 (Receipt용)
    private func itemTypeName(for item: any WorkshopItem) -> String {
        switch item {
        case is KeyringTemplate: return "template"
        case is Background: return "background"
        case is Carabiner: return "carabiner"
        case is Particle: return "particle"
        case is Sound: return "sound"
        default: return "unknown"
        }
    }

    /// 구매내역(Receipt) 저장
    private func saveReceipt(
        item: any WorkshopItem,
        itemId: String,
        userRef: DocumentReference
    ) async throws {
        let receiptData: [String: Any] = [
            "itemID": itemId,
            "itemName": item.name,
            "itemType": itemTypeName(for: item),
            "price": item.workshopPrice,
            "purchasedAt": Timestamp(date: Date())
        ]
        try await userRef.collection("Receipts").addDocument(data: receiptData)
    }

    /// UserManager 데이터 갱신
    private func refreshUserData(userId: String, userManager: UserManager) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            userManager.loadUserInfo(uid: userId) { _ in
                continuation.resume()
            }
        }
    }
}
