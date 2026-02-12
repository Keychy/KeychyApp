//
//  HomeViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/16/24.
//

import SwiftUI
import FirebaseFirestore

@Observable
class HomeViewModel {
    // MARK: - Properties

    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    var keyringDataList: [MultiKeyringScene.KeyringData] = []

    /// 씬 준비 완료 여부
    var isSceneReady = false

    /// 데이터 로드 완료 여부
    var isDataLoaded = false

    /// 마지막으로 로드한 뭉치 ID (뭉치 변경 감지용)
    private var lastLoadedBundleId: String?

    /// 씬 준비 완료 대기 Task (새 로딩 시작 시 취소용)
    private var sceneReadyTask: Task<Void, Never>?

    /// 뭉치 전환 Task (빠른 연속 전환 시 이전 전환 취소용)
    private var switchBundleTask: Task<Void, Never>?

    /// 씬 세대 카운터 (이전 씬의 콜백이 현재 씬에 영향주지 않도록 구분)
    private(set) var sceneGeneration = 0

    /// 다른 화면에서 키링/뭉치 수정 후 홈 리프레시 필요 여부
    static var needsRefresh: Bool = false
    
    /// 네트워크 에러 발생 여부
    var hasNetworkError: Bool = false

    /// 마지막 씬 생성 시점의 키링 URL 시그니처 (.id() 변경 감지용)
    private var lastSceneKeyringSignature: String = ""

    // MARK: - Private Properties

    private let db = Firestore.firestore()

    // MARK: - Data Loading

    /// 메인 뭉치 데이터를 로드하고 뷰 상태를 초기화
    /// 1. 사용자의 모든 뭉치 목록을 가져옴
    /// 2. 메인으로 설정된 뭉치를 찾아 선택
    /// 3. 선택된 뭉치의 키링들을 Firestore에서 가져와 KeyringData 리스트 생성
    
    @MainActor
    func loadMainBundle(collectionViewModel: CollectionViewModel, bundleViewModel: BundleViewModel, onBackgroundLoaded: (() -> Void)?) async {
        print("🔵 [loadMainBundle] 시작 - isSceneReady=\(isSceneReady), isDataLoaded=\(isDataLoaded)")

        // 리프레시 필요 시 캐시 무효화
        if Self.needsRefresh {
            Self.needsRefresh = false
            lastLoadedBundleId = nil
        }

        // 이미 데이터가 로드되었고, 같은 뭉치가 선택된 상태면 스킵 (탭 전환 후 돌아올 때)
        if isDataLoaded,
           let currentBundle = bundleViewModel.selectedBundle,
           lastLoadedBundleId == currentBundle.documentId {
            print("🔵 [loadMainBundle] 캐시 히트 - 스킵")
            return
        }

        let uid = UserManager.shared.userUID
        guard !uid.isEmpty else {
            print("🔴 [loadMainBundle] uid 비어있음 → isSceneReady = true")
            isSceneReady = true
            return
        }

        // 1. 배경 및 카라비너 데이터 로드
        print("🔵 [loadMainBundle] 1. 배경/카라비너 로드 시작")
        await collectionViewModel.loadBackgroundsAndCarabiners()
        print("🔵 [loadMainBundle] 1. 완료 - backgrounds=\(bundleViewModel.backgrounds.count), carabiners=\(bundleViewModel.carabiners.count)")

        // 2. 번들 목록 로드
        print("🔵 [loadMainBundle] 2. 번들 로드 시작")
        await withCheckedContinuation { continuation in
            bundleViewModel.fetchAllBundles(uid: uid) { _ in
                continuation.resume()
            }
        }
        print("🔵 [loadMainBundle] 2. 완료 - bundles=\(bundleViewModel.sortedBundles.count)")

        // 3. 메인 뭉치 찾기 (아직 selectedBundle에 설정하지 않음 — 배치 업데이트를 위해)
        var bundle: KeyringBundle
        if let mainBundle = bundleViewModel.sortedBundles.first(where: { $0.isMain }) {
            bundle = mainBundle
        } else if let firstBundle = bundleViewModel.sortedBundles.first {
            bundle = firstBundle
        } else {
            print("🔴 [loadMainBundle] 번들 0개 → isSceneReady = true")
            isSceneReady = true
            onBackgroundLoaded?()
            return
        }
        print("🔵 [loadMainBundle] 3. 선택된 번들: \(bundle.name), keyrings=\(bundle.keyrings.count), selectedCarabiner=\(bundle.selectedCarabiner)")

        // 4. 배경 resolve (로컬 변수에만 저장)
        var resolvedBackground = bundleViewModel.resolveBackground(from: bundle.selectedBackground)

        // 배경이 없으면 첫 번째 배경으로 fallback + Firebase 업데이트
        if resolvedBackground == nil, let firstBackground = bundleViewModel.backgrounds.first {
            resolvedBackground = firstBackground

            if let documentId = bundle.documentId, let backgroundId = firstBackground.id {
                await updateBundleBackground(documentId: documentId, backgroundId: backgroundId)

                // bundles 배열만 업데이트 (selectedBundle은 아직 변경 X)
                bundle.selectedBackground = backgroundId
                if let index = bundleViewModel.bundles.firstIndex(where: { $0.documentId == documentId }) {
                    bundleViewModel.bundles[index].selectedBackground = backgroundId
                }
            }
        }
        print("🔵 [loadMainBundle] 4. 배경 resolve: \(resolvedBackground?.id ?? "nil")")

        // 5. 카라비너 resolve (로컬 변수에만 저장)
        var resolvedCarabiner = bundleViewModel.resolveCarabiner(from: bundle.selectedCarabiner)
        print("🔵 [loadMainBundle] 5. 카라비너 resolve: \(resolvedCarabiner?.id ?? "nil") (원본 ID=\(bundle.selectedCarabiner))")
        if resolvedCarabiner == nil, let fallback = bundleViewModel.carabiners.first {
            resolvedCarabiner = fallback
            print("🟡 [loadMainBundle] 카라비너 fallback 적용: \(fallback.id ?? "nil")")
        }

        guard let carabiner = resolvedCarabiner else {
            print("🔴 [loadMainBundle] 카라비너 없음 (fallback도 실패) → isSceneReady = true")
            isSceneReady = true
            return
        }

        // 6. 키링 데이터 생성 (아직 UI 상태 변경 없음)
        print("🔵 [loadMainBundle] 6. keyringDataList 생성 시작")
        let newKeyringDataList = await createKeyringDataList(bundle: bundle, carabiner: carabiner)
        print("🔵 [loadMainBundle] 6. 완료 - keyringDataList=\(newKeyringDataList.count)")

        // 7. 모든 상태를 한 번에 업데이트 (SwiftUI body 재평가 최소화)
        // switchBundle과 동일한 배치 업데이트 패턴
        bundleViewModel.selectedBundle = bundle
        bundleViewModel.selectedBackground = resolvedBackground
        bundleViewModel.selectedCarabiner = carabiner
        keyringDataList = newKeyringDataList

        // 데이터 로드 완료 표시
        lastLoadedBundleId = bundle.documentId
        isDataLoaded = true
        print("🟢 [loadMainBundle] 완료 - isSceneReady=\(isSceneReady), isDataLoaded=\(isDataLoaded), sceneGeneration=\(sceneGeneration)")
    }

    /// 뭉치의 키링들을 MultiKeyringScene.KeyringData 배열로 변환
    /// - Parameters:
    ///   - bundle: 현재 뭉치
    ///   - carabiner: 선택된 카라비너 (위치 정보 제공)
    /// - Returns: 3D 씬에서 사용할 KeyringData 배열
    private func createKeyringDataList(bundle: KeyringBundle, carabiner: Carabiner) async -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        for (index, keyringId) in bundle.keyrings.enumerated() {
            // 유효하지 않은 키링 ID 필터링
            guard index < carabiner.maxKeyringCount,
                  keyringId != "none",
                  !keyringId.isEmpty else { continue }

            // Firebase에서 키링 정보 가져오기
            guard let keyringInfo = await fetchKeyringInfo(keyringId: keyringId) else { continue }

            // 커스텀 사운드 URL 처리 (HTTP/HTTPS로 시작하는 경우)
            let customSoundURL: URL? = {
                if keyringInfo.soundId.hasPrefix("https://") || keyringInfo.soundId.hasPrefix("http://") {
                    return URL(string: keyringInfo.soundId)
                }
                return nil
            }()

            // KeyringData 생성
            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyringInfo.bodyImage,
                templateId: keyringInfo.selectedTemplate,
                soundId: keyringInfo.soundId,
                customSoundURL: customSoundURL,
                particleId: keyringInfo.particleId,
                hookOffsetY: keyringInfo.hookOffsetY,
                chainLength: keyringInfo.chainLength
            )
            dataList.append(data)
        }
        
        // 키링 데이터까지 불러오고 난 후에도 키링의 개수가 0개라면 바로 씬을 준비 완료 상태로 체크
        if dataList.isEmpty {
            isSceneReady = true
        }
        
        return dataList
    }

    /// Firestore에서 키링 정보를 가져옴
    private func fetchKeyringInfo(keyringId: String) async -> KeyringInfo? {
        do {
            let document = try await db.collection("Keyring").document(keyringId).getDocument()

            guard let data = document.data(),
                  let bodyImage = data["bodyImage"] as? String,
                  let soundId = data["soundId"] as? String,
                  let particleId = data["particleId"] as? String else {
                return nil
            }

            let hookOffsetY = data["hookOffsetY"] as? CGFloat ?? 0.0
            let chainLength = data["chainLength"] as? Int ?? 5
            let selectedTemplate = data["selectedTemplate"] as? String

            return KeyringInfo(
                id: keyringId,
                bodyImage: bodyImage,
                selectedTemplate: selectedTemplate,
                soundId: soundId,
                particleId: particleId,
                hookOffsetY: hookOffsetY,
                chainLength: chainLength
            )
        } catch {
            return nil
        }
    }

    /// 번들의 배경을 Firebase에 업데이트
    private func updateBundleBackground(documentId: String, backgroundId: String) async {
        try? await db.collection("KeyringBundle").document(documentId).updateData([
            "selectedBackground": backgroundId
        ])
    }

    /// 대표뭉치 설정 (isMain 업데이트) - Batch write로 원자성 보장
    /// - Parameters:
    ///   - newMainBundle: 새로 대표뭉치로 설정할 뭉치
    ///   - bundleViewModel: BundleViewModel
    @MainActor
    private func updateMainBundle(newMainBundle: KeyringBundle, bundleViewModel: BundleViewModel) async {
        guard let newMainDocId = newMainBundle.documentId else { return }

        let previousMainBundle = bundleViewModel.bundles.first(where: { $0.isMain })
        let batch = db.batch()

        // 1. 기존 대표뭉치 해제 (batch에 추가)
        if let previousMain = previousMainBundle,
           let previousDocId = previousMain.documentId,
           previousDocId != newMainDocId {
            let previousRef = db.collection("KeyringBundle").document(previousDocId)
            batch.updateData(["isMain": false], forDocument: previousRef)
        }

        // 2. 새 대표뭉치 설정 (batch에 추가)
        let newMainRef = db.collection("KeyringBundle").document(newMainDocId)
        batch.updateData(["isMain": true], forDocument: newMainRef)

        // 3. Batch commit (원자적 업데이트)
        do {
            try await batch.commit()

            // 성공 시 로컬 상태 업데이트
            if let previousMain = previousMainBundle,
               let previousDocId = previousMain.documentId,
               previousDocId != newMainDocId,
               let index = bundleViewModel.bundles.firstIndex(where: { $0.documentId == previousDocId }) {
                bundleViewModel.bundles[index].isMain = false
            }
            if let index = bundleViewModel.bundles.firstIndex(where: { $0.documentId == newMainDocId }) {
                bundleViewModel.bundles[index].isMain = true
            }
        } catch {
            // 실패 시 로컬 상태는 변경하지 않음 (데이터 일관성 유지)
        }
    }

    /// 키링 데이터 변경 감지 시 씬 준비 상태 초기화
    func handleKeyringDataChange() {
        print("🟠 [handleKeyringDataChange] 호출 - keyringDataList=\(keyringDataList.count), isSceneReady=\(isSceneReady)")
        // 빈 뭉치면 이미 createKeyringDataList에서 isSceneReady = true 설정됨
        // 다시 false로 리셋하면 무한로딩 발생
        guard !keyringDataList.isEmpty else {
            print("🟠 [handleKeyringDataChange] 빈 리스트 → 스킵 (isSceneReady 유지)")
            lastSceneKeyringSignature = ""
            return
        }

        // .id() 변경 여부 체크: bodyImageURL이 같으면 씬이 재생성되지 않음
        // 씬이 재생성되지 않으면 onSetupComplete 콜백이 안 오므로
        // isSceneReady = false로 바꾸면 무한로딩 발생
        let newSignature = keyringDataList.map(\.bodyImageURL).joined(separator: ",")
        guard newSignature != lastSceneKeyringSignature else {
            print("🟠 [handleKeyringDataChange] 같은 키링 URL → .id() 변경 없음 → 스킵")
            return
        }
        lastSceneKeyringSignature = newSignature

        // 이전 씬의 준비 완료 Task 취소
        sceneReadyTask?.cancel()
        sceneReadyTask = nil
        print("🟠 [handleKeyringDataChange] 씬 재생성 필요 → isSceneReady → false")

        withAnimation(.easeIn(duration: 0.2)) {
            isSceneReady = false
        }
    }

    /// 모든 키링 준비 완료되면 0.5초 대기 후 로딩을 삭제함
    /// - Parameter generation: 이 콜백을 생성한 씬의 세대 번호
    func handleAllKeyringsReady(generation: Int) {
        print("🟣 [handleAllKeyringsReady] 호출 - generation=\(generation), sceneGeneration=\(sceneGeneration)")
        // 이전 씬의 콜백이면 무시 (세대가 다르면 이미 새 씬이 생성된 것)
        guard generation == sceneGeneration else {
            print("🔴 [handleAllKeyringsReady] 세대 불일치! generation=\(generation) != sceneGeneration=\(sceneGeneration) → 무시")
            return
        }

        sceneReadyTask?.cancel()

        sceneReadyTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else {
                print("🔴 [handleAllKeyringsReady] Task 취소됨")
                return
            }

            await MainActor.run { [weak self] in
                guard let self, generation == self.sceneGeneration else {
                    print("🔴 [handleAllKeyringsReady] sleep 후 세대 불일치 → 무시")
                    return
                }
                print("🟢 [handleAllKeyringsReady] isSceneReady → true (generation=\(generation))")
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isSceneReady = true
                }
            }
        }
    }

    /// 네트워크 에러 후 재시도
    @MainActor
    func retryLoadMainBundle(collectionViewModel: CollectionViewModel, bundleViewModel: BundleViewModel, onBackgroundLoaded: (() -> Void)?) async {
        guard NetworkManager.shared.isConnected else { return }
        hasNetworkError = false
        await loadMainBundle(collectionViewModel: collectionViewModel, bundleViewModel: bundleViewModel, onBackgroundLoaded: onBackgroundLoaded)
    }

    // MARK: - Bundle Switching

    /// 뭉치 전환 요청 (이전 전환 진행 중이면 취소 후 새 전환 시작)
    @MainActor
    func requestBundleSwitch(to bundle: KeyringBundle, collectionViewModel: CollectionViewModel, bundleViewModel: BundleViewModel) {
        // 이전 뭉치 전환 Task 취소
        switchBundleTask?.cancel()

        withAnimation(.easeIn(duration: 0.2)) {
            isSceneReady = false
        }

        switchBundleTask = Task {
            await switchBundle(to: bundle, collectionViewModel: collectionViewModel, bundleViewModel: bundleViewModel)
        }
    }

    /// 다른 뭉치로 전환 (내부 구현, requestBundleSwitch를 통해 호출)
    @MainActor
    private func switchBundle(to bundle: KeyringBundle, collectionViewModel: CollectionViewModel, bundleViewModel: BundleViewModel) async {
        // 1. 대표뭉치 설정 (isMain 업데이트)
        await updateMainBundle(newMainBundle: bundle, bundleViewModel: bundleViewModel)

        // 취소 체크: 다른 뭉치 전환 요청이 들어왔으면 중단
        guard !Task.isCancelled else { return }

        // 2. 모든 데이터 먼저 준비 (UI 업데이트 전)
        let resolvedBackground = bundleViewModel.resolveBackground(from: bundle.selectedBackground)
        // 카라비너 resolve 실패 시 첫 번째 카라비너로 fallback
        var resolvedCarabiner = bundleViewModel.resolveCarabiner(from: bundle.selectedCarabiner)
        if resolvedCarabiner == nil, let fallback = bundleViewModel.carabiners.first {
            resolvedCarabiner = fallback
        }

        guard let carabiner = resolvedCarabiner else {
            isSceneReady = true
            return
        }

        // 3. 키링 데이터 생성 (새 카라비너 기준)
        let newKeyringDataList = await createKeyringDataList(bundle: bundle, carabiner: carabiner)

        // 취소 체크: 키링 데이터 생성 중 다른 전환 요청이 들어왔으면 중단
        guard !Task.isCancelled else { return }

        // 4. 모든 상태를 한 번에 업데이트 (SwiftUI re-render 최소화)
        bundleViewModel.selectedBundle = bundle
        bundleViewModel.selectedBackground = resolvedBackground ?? bundleViewModel.backgrounds.first
        bundleViewModel.selectedCarabiner = carabiner
        keyringDataList = newKeyringDataList

        // 데이터 로드 완료 표시
        lastLoadedBundleId = bundle.documentId
        isDataLoaded = true
    }

}
