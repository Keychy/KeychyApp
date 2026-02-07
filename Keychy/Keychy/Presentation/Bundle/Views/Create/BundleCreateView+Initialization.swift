//
//  BundleCreateView+Initialization.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI

// MARK: - 데이터 초기화
extension BundleCreateView {

    /// 초기 데이터 로딩
    func initializeData() async {
        // 사용자가 소유한 배경과 카라비너 데이터를 가져옴
        await loadUserOwnedItems()
    }

    /// 화면이 다시 나타날 때 데이터 새로고침
    func refreshData() async {
        guard let _ = UserManager.shared.currentUser else {
            return
        }

        // 현재 선택된 아이템의 ID 저장
        let currentBackgroundId = bundleVM.newSelectedBackground?.background.id
        let currentCarabinerId = bundleVM.newSelectedCarabiner?.carabiner.id

        // 배경 데이터 새로고침
        await withCheckedContinuation { continuation in
            bundleVM.fetchAllBackgrounds { _ in
                // 이전에 선택했던 배경을 다시 찾아서 선택 (구매 상태가 업데이트됨)
                if let bgId = currentBackgroundId {
                    self.bundleVM.newSelectedBackground = bundleVM.backgroundViewData.first { $0.background.id == bgId }
                }
                continuation.resume()
            }
        }

        // 카라비너 데이터 새로고침
        await withCheckedContinuation { continuation in
            bundleVM.fetchAllCarabiners { _ in
                // 이전에 선택했던 카라비너를 다시 찾아서 선택 (구매 상태가 업데이트됨)
                if let cbId = currentCarabinerId {
                    self.bundleVM.newSelectedCarabiner = bundleVM.carabinerViewData.first { $0.carabiner.id == cbId }
                }
                continuation.resume()
            }
        }
    }

    /// 사용자가 소유한 배경과 카라비너 아이템들을 로드
    func loadUserOwnedItems() async {
        guard let _ = UserManager.shared.currentUser else {
            return
        }

        let uid = UserManager.shared.userUID

        // 배경 데이터 로드
        await withCheckedContinuation { continuation in
            bundleVM.fetchAllBackgrounds { _ in
                continuation.resume()
            }
        }

        // 카라비너 데이터 로드
        await withCheckedContinuation { continuation in
            bundleVM.fetchAllCarabiners { _ in
                continuation.resume()
            }
        }

        // 코인 충전 후 복귀 시 저장된 선택 복원
        bundleVM.restoreSelectionIfNeeded()

        // 배경 선택 (복원된 값이 없을 때만)
        if bundleVM.newSelectedBackground == nil {
            // 공방에서 미리 선택된 배경이 있으면 해당 배경 선택
            if let preSelectedId = bundleVM.preSelectedBackgroundId {
                bundleVM.newSelectedBackground = bundleVM.backgroundViewData.first { bg in
                    bg.background.id == preSelectedId
                }
                bundleVM.preSelectedBackgroundId = nil
            }
            // 미리 선택된 배경이 없으면 "퍼플키치"를 기본으로 선택
            if bundleVM.newSelectedBackground == nil {
                bundleVM.newSelectedBackground = bundleVM.backgroundViewData.first { bg in
                    bg.background.backgroundName == "퍼플키치"
                } ?? bundleVM.backgroundViewData.first
            }
        }

        // 카라비너 선택 (복원된 값이 없을 때만)
        if bundleVM.newSelectedCarabiner == nil {
            // 공방에서 미리 선택된 카라비너가 있으면 해당 카라비너 선택
            if let preSelectedId = bundleVM.preSelectedCarabinerId {
                bundleVM.newSelectedCarabiner = bundleVM.carabinerViewData.first { cb in
                    cb.carabiner.id == preSelectedId
                }
                bundleVM.preSelectedCarabinerId = nil
            }
            // 미리 선택된 카라비너가 없으면 "웰컴 키치"를 기본으로 선택
            if bundleVM.newSelectedCarabiner == nil {
                bundleVM.newSelectedCarabiner = bundleVM.carabinerViewData.first { cb in
                    cb.carabiner.carabinerName == "웰컴 키치"
                } ?? bundleVM.carabinerViewData.first
            }
        }

        // 키링 데이터 로드
        await withCheckedContinuation { continuation in
            collectionVM.fetchUserCollectionData(uid: uid) { success in
                if success {
                    collectionVM.fetchUserKeyrings(uid: uid) { success in
                        if success {
                            bundleVM.keyring = collectionVM.keyring
                        }
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
