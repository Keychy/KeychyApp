//
//  BundleEditView+Initialization.swift
//  Keychy
//
//  Created by 김서현 on 1/13/26.
//

import SwiftUI
import FirebaseFirestore
import Nuke

extension BundleEditView {
    func initializeData() async {
        resetSceneState()

        await loadUserKeyring()

        await loadBackgroundAndCarabiner()

        // 시트 이미지 프리페칭 (백그라운드에서 Nuke 캐시에 미리 로드)
        prefetchSheetImages()
    }

    /// 배경/카라비너 썸네일을 Nuke 캐시에 미리 로드
    private func prefetchSheetImages() {
        let bgURLs = bundleVM.backgroundViewData.compactMap { URL(string: $0.background.backgroundImage) }
        let cbURLs = bundleVM.carabinerViewData.compactMap { URL(string: $0.carabiner.carabinerImage[0]) }
        let prefetcher = ImagePrefetcher()
        prefetcher.startPrefetching(with: bgURLs + cbURLs)
    }
    
    func resetSceneState() {
        isSceneReady = false
        isKeyringSheetLoading = true
    }
    
    // 사용자 키링 데이터 로드
    func loadUserKeyring() async {
        let uid = UserManager.shared.userUID
        await withCheckedContinuation { continuation in
            collectionVM.fetchUserKeyrings(uid: uid) { success in
                bundleVM.keyring = collectionVM.keyring
                continuation.resume()
            }
        }
    }
    
    func loadBackgroundAndCarabiner() async {
        // 배경 + 카라비너 병렬 로드
        async let bgTask: Void = withCheckedContinuation { continuation in
            bundleVM.fetchAllBackgrounds { _ in continuation.resume() }
        }
        async let cbTask: Void = withCheckedContinuation { continuation in
            bundleVM.fetchAllCarabiners { _ in continuation.resume() }
        }
        await bgTask
        await cbTask

        // 현재 뭉치의 배경/카라비너로 초기화
        if let selectedBundle = bundleVM.selectedBundle {
            bundleVM.newSelectedBackground = bundleVM.backgroundViewData.first {
                $0.background.id == selectedBundle.selectedBackground
            }
            bundleVM.newSelectedCarabiner = bundleVM.carabinerViewData.first {
                $0.carabiner.id == selectedBundle.selectedCarabiner
            }
        }

        // 코인 충전 후 복귀 시 저장된 선택 복원
        bundleVM.restoreSelectionIfNeeded()

        // Firebase 키링 데이터 초기화 (비동기)
        Task {
            await self.initializeSelectedKeyringsFromFirebase()
            self.updateKeyringDataList()
            isKeyringSheetLoading = false
            if !keyringDataList.isEmpty {
                sceneRefreshId = UUID()
            }
        }

        if keyringDataList.isEmpty {
            isSceneReady = true
        }
    }
    
    /// Firebase 데이터를 로컬 상태로 한 번만 초기화
    func initializeSelectedKeyringsFromFirebase() async {
        guard let bundle = bundleVM.selectedBundle else {
            return
        }
        
        let result = await bundleVM.convertBundleToSelectedKeyrings(bundle: bundle)
        bundleVM.selectedKeyrings = result.0
        bundleVM.keyringOrder = result.1
    }
}
