//
//  PurchaseHistoryVIewModel.swift
//  Keychy
//
//  Created by 길지훈 on 1/28/26.
//

import SwiftUI
import FirebaseFirestore

@Observable
class PurchaseHistoryViewModel {
    var receipts: [Receipt] = []
    var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    /// 구매내역 가져오기
    func fetchReceipts(userId: String) async {
        isLoading = true
        
        do {
            let snapshot = try await db
                .collection("User")
                .document(userId)
                .collection("Receipts")
                .order(by: "purchasedAt", descending: true)
                .getDocuments()
            
            receipts = snapshot.documents.compactMap { doc in
                /// 각 Firebase 문서를 Codable 모델로 변환, Receipt 타입으로 변환
                try? doc.data(as: Receipt.self)
            }
            
        } catch {
            print("구매내역 로드 실패: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
