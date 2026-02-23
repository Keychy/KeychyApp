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
        await withCheckedContinuation { continuation in
            bundleVM.fetchAllBackgrounds { _ in
                // 현재 뭉치의 배경으로 항상 초기화
                if let selectedBundle = bundleVM.selectedBundle {
                    bundleVM.newSelectedBackground = bundleVM.backgroundViewData.first { bgData in
                        bgData.background.id == selectedBundle.selectedBackground
                    }
                }

                bundleVM.fetchAllCarabiners { _ in
                    // 현재 뭉치의 카라비너로 항상 초기화
                    if let selectedBundle = bundleVM.selectedBundle {
                        bundleVM.newSelectedCarabiner = bundleVM.carabinerViewData.first { cbData in
                            cbData.carabiner.id == selectedBundle.selectedCarabiner
                        }
                    }

                    // 코인 충전 후 복귀 시 저장된 선택 복원
                    bundleVM.restoreSelectionIfNeeded()
                    
                    Task {
                        // Firebase 데이터를 한 번만 로컬 상태로 초기화
                        await self.initializeSelectedKeyringsFromFirebase()
                        // 이후부터는 완전히 로컬 데이터만 사용
                        self.updateKeyringDataList()
                        
                        isKeyringSheetLoading = false
                        
                        // 씬 재구성 조건 설정
                        if !keyringDataList.isEmpty {
                            sceneRefreshId = UUID()
                        }
                    }
                    // 키링 데이터까지 불러오고 난 후에도 키링의 개수가 0개라면 바로 씬을 준비 완료 상태로 체크
                    if keyringDataList.isEmpty {
                        isSceneReady = true
                    }
                    
                    continuation.resume()
                }
            }
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
