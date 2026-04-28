//
//  TemplatePreviewViewModel.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-13.
//

import SwiftUI
import FirebaseFirestore

/// TemplatePreviewBody의 구매/보관함 비즈니스 로직 담당
@Observable
@MainActor
final class TemplatePreviewViewModel {
    // MARK: - 구매 관련 상태
    var showPurchaseSheet = false
    var purchasePopupScale: CGFloat = 0.3
    var showPurchasingLoading = false
    var showPurchaseSuccessAlert = false
    var showPurchaseFailAlert = false
    var purchaseFailScale: CGFloat = 0.3

    // MARK: - 보관함 용량 관련
    var showInvenFullAlert = false

    // MARK: - 템플릿 보유 여부
    func isOwned(template: KeyringTemplate?, user: KeychyUser?) -> Bool {
        guard let user, let templateId = template?.id else { return false }
        return user.templates.contains(templateId)
    }

    // MARK: - 구매 팝업 표시
    func showPurchasePopup() {
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }
        showPurchaseSheet = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            purchasePopupScale = 1.0
        }
    }

    // MARK: - 구매 팝업 닫기
    func dismissPurchasePopup() async {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            purchasePopupScale = 0.3
        }
        try? await Task.sleep(for: .seconds(0.2))
        showPurchaseSheet = false
    }

    // MARK: - 구매 처리
    func handlePurchase(template: KeyringTemplate, userManager: UserManager) async {
        await dismissPurchasePopup()
        try? await Task.sleep(for: .seconds(0.1))

        showPurchasingLoading = true

        // ItemPurchaseManager를 통해 구매 처리
        let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(
            template,
            userManager: userManager
        )

        showPurchasingLoading = false
        try? await Task.sleep(for: .seconds(0.1))

        switch result {
        case .success:
            showPurchaseSuccessAlert = true
        case .insufficientCoins:
            showPurchaseFailAlert = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                purchaseFailScale = 1.0
            }
        case .failed(let message):
            print("구매 실패: \(message)")
        }
    }

    // MARK: - 보관함 체크 후 만들기
    func checkInventoryAndMake(userManager: UserManager, onMake: @escaping () -> Void) {
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }
        guard let userId = userManager.currentUser?.id else { return }

        Task {
            let hasSpace = await checkInventoryCapacity(userId: userId)
            if hasSpace {
                onMake()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showInvenFullAlert = true
                }
            }
        }
    }

    // MARK: - 구매 실패 팝업 닫기
    func dismissPurchaseFailAlert() async {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            purchaseFailScale = 0.3
        }
        try? await Task.sleep(for: .seconds(0.2))
        showPurchaseFailAlert = false
    }

    // MARK: - Firebase 보관함 용량 확인
    /// CollectionViewModel 인스턴스 없이 직접 Firestore 조회 (async/await)
    private func checkInventoryCapacity(userId: String) async -> Bool {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("User")
                .document(userId)
                .getDocument()

            guard let data = snapshot.data(),
                  let keyrings = data["keyrings"] as? [String],
                  let maxKeyringCount = data["maxKeyringCount"] as? Int else {
                return false
            }

            return keyrings.count < maxKeyringCount
        } catch {
            return false
        }
    }
}
