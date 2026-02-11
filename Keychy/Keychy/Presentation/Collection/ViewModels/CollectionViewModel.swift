//
//  CollectionViewModel.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore
import SpriteKit

@Observable
class CollectionViewModel {
    
    // MARK: - 데이터
    var keyring: [Keyring] = []
    var tags: [String] = [] // 태그
    
    // MARK: - 공통 상태
    var isLoading = false
    var selectedSort: String = "최신순" // 기본값
    var maxKeyringCount: Int = 100 // 기본값
    var coin: Int = 0
    var copyVoucher: Int = 0
    var selectedKeyrings: [Keyring] = []
    var hasNetworkError: Bool = false
    
    // MARK: - 탭 토글 (true = 키링, false = 뭉치)
    var collectionToggle: Bool = true {
        didSet {
            // 탭 전환해도 정렬 상태는 유지 (각 탭이 독립적으로 정렬방식 유지)
        }
    }

    /// 다른 화면에서 보관함 이동 시 뭉치 탭으로 시작할지 여부
    static var shouldStartWithBundleTab: Bool = false
    
    // Firestore 문서 ID 매핑: 로컬 Keyring(UUID) -> Firestore 문서 ID(String)
    var keyringDocumentIdByLocalId: [UUID: String] = [:]

    // MARK: - Shared Data
    let dataManager = WorkshopDataManager.shared

    // MARK: - Computed Properties
    // 카테고리 목록 (전체 포함)
    var categories: [String] {
        getCategories()
    }

    // MARK: - 초기화
    init() {}

    // MARK: - Data Loading
    /// 배경 및 카라비너 데이터 로드 (캐싱된 데이터 활용)
    func loadBackgroundsAndCarabiners() async {
        await dataManager.fetchBackgroundsIfNeeded()
        await dataManager.fetchCarabinersIfNeeded()

        // Lottie 아이템 JSON 프리다운로드
        let lottieBackgrounds = dataManager.backgrounds.filter { $0.isLottie }
        let lottieCarabiners = dataManager.carabiners.filter { $0.isLottie }
        if !lottieBackgrounds.isEmpty || !lottieCarabiners.isEmpty {
            Task {
                for bg in lottieBackgrounds {
                    await LottieItemManager.shared.downloadBackgroundLottie(bg)
                }
                for cb in lottieCarabiners {
                    await LottieItemManager.shared.downloadCarabinerLottie(cb)
                }
            }
        }
    }

    /// 네트워크 에러 후 재시도
    func retryFetchData(userId: String) async {
        guard NetworkManager.shared.isConnected else { return }
        hasNetworkError = false

        await withCheckedContinuation { continuation in
            fetchUserCollectionData(uid: userId) { success in
                if success {
                    self.fetchUserKeyrings(uid: userId) { _ in
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

