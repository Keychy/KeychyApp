//
//  BundleViewModel.swift
//  Keychy
//
//  Created by 김서현 on 1/9/26.
//

// MARK: - BundleViewModel (메인)
//
// 뭉치 관련 상태 관리. 프로퍼티만 포함.
//
// Extension 파일:
//   +Types     - 데이터 구조체
//   +Fetch     - Firebase 읽기
//   +CRUD      - Firebase 쓰기
//   +Edit      - 편집 로직
//   +Purchase  - 구매 로직
//   +Helpers   - 유틸리티
//   +Cache     - 캐시/최적화
//   +Views     - UI 컴포넌트

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@Observable
class BundleViewModel {

    // MARK: - Firebase

    var db: Firestore {
        Firestore.firestore()
    }

    // MARK: - Shared Data Manager

    let dataManager = WorkshopDataManager.shared

    // MARK: - 배경/카라비너 원본 데이터

    var backgrounds: [Background] { dataManager.backgrounds }
    var selectedBackground: Background?

    var carabiners: [Carabiner] { dataManager.carabiners }
    var selectedCarabiner: Carabiner?

    // MARK: - 공방에서 미리 선택된 아이템 ID

    var preSelectedBackgroundId: String?
    var preSelectedCarabinerId: String?

    // MARK: - 뭉치 설정

    var maxBundleNameCount: Int = 9

    // MARK: - 뭉치 생성 시 선택된 키링

    var selectedKeyringsForBundle: [Int: Keyring] = [:]

    // MARK: - 뭉치 캡쳐 이미지

    var bundleCapturedImage: Data?

    // MARK: - 현재 선택된 뭉치

    var selectedBundle: KeyringBundle?

    // MARK: - 사용자 데이터

    var bundles: [KeyringBundle] = []
    var keyring: [Keyring] = []

    // MARK: - 로딩 상태

    var isLoading = false
    var isPurchasing = false

    // MARK: - 시트 필터/정렬 상태

    var sheetSortOrder: String = "최신순"
    var sheetShowFreeOnly: Bool = false
    var sheetShowOwnedOnly: Bool = false
    var showSheetSortSheet: Bool = false

    // MARK: - 편집 화면용 데이터

    var newSelectedBackground: BackgroundViewData?
    var newSelectedCarabiner: CarabinerViewData?
    var selectedKeyringPosition: Int = 0
    var keyringOrder: [Int] = []
    var selectedKeyrings: [Int: Keyring] = [:]

    // MARK: - 화면 표시용 배열

    var _backgroundViewData: [BackgroundViewData] = []
    var _carabinerViewData: [CarabinerViewData] = []

    var backgroundViewData: [BackgroundViewData] {
        get { _backgroundViewData }
        set { _backgroundViewData = newValue }
    }
    var carabinerViewData: [CarabinerViewData] {
        get { _carabinerViewData }
        set { _carabinerViewData = newValue }
    }

    // MARK: - 정렬된 뭉치

    var sortedBundles: [KeyringBundle] {
        bundles.sorted { a, b in
            if a.isMain != b.isMain {
                return a.isMain
            }
            return a.createdAt > b.createdAt
        }
    }

    // MARK: - 구성 ID 저장소 (편집 → 상세 화면 전환용)

    var _returnBackgroundId: String?
    var _returnCarabinerId: String?
    var _returnKeyringsId: String?

    var returnBackgroundId: String? {
        get { _returnBackgroundId }
        set { _returnBackgroundId = newValue }
    }
    var returnCarabinerId: String? {
        get { _returnCarabinerId }
        set { _returnCarabinerId = newValue }
    }
    var returnKeyringsId: String? {
        get { _returnKeyringsId }
        set { _returnKeyringsId = newValue }
    }

    // MARK: - 마지막 로드 구성 ID (씬 리로드 최적화용)

    var _lastBackgroundIdForDetail: String?
    var _lastCarabinerIdForDetail: String?
    var _lastKeyringsIdForDetail: String?

    var lastBackgroundIdForDetail: String {
        get { _lastBackgroundIdForDetail ?? "" }
        set { _lastBackgroundIdForDetail = newValue }
    }
    var lastCarabinerIdForDetail: String {
        get { _lastCarabinerIdForDetail ?? "" }
        set { _lastCarabinerIdForDetail = newValue }
    }
    var lastKeyringsIdForDetail: String {
        get { _lastKeyringsIdForDetail ?? "" }
        set { _lastKeyringsIdForDetail = newValue }
    }
}
