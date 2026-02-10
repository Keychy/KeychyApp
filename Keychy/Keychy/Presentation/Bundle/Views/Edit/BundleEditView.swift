//
//  BundleEditView.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI
import NukeUI
import SceneKit
import FirebaseFirestore

struct BundleEditView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var collectionVM: CollectionViewModel
    @State var bundleVM: BundleViewModel
    
    @State var selectedCategory: String = ""
    @State var selectCarabiner: CarabinerViewData?
    
    // MARK: - Loading
    @State var isSceneReady = false
    @State var isNavigatingAway = false // 화면 전환 중인지 추적
    @State var isKeyringSheetLoading: Bool = true
    @State var isCapturing: Bool = false
    
    // MARK: - Sheet
    @State var showItemSheet: Bool = false
    @State var isBackgroundMode: Bool = true  // true: 배경, false: 카라비너
    @State var showPurchaseSheet = false
    @State var showSelectKeyringSheet = false
    
    // MARK: - Alert
    @State var showChangeCarabinerAlert: Bool = false
    
    // 구매 관련
    @State var showPurchaseSuccessAlert = false
    @State var showPurchaseFailAlert = false
    
    // MultiKeyringScene에 전달할 키링 데이터 리스트
    @State var keyringDataList: [MultiKeyringScene.KeyringData] = []
    
    @State var selectedPosition = 0
    @State var sceneRefreshId = UUID()
    @State var keyringSearchText: String = ""

    // 공통 그리드 컬럼 (배경, 카라비너, 키링 모두 동일)
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    // 시트 높이 (화면의 약 43%에 해당)
    @State var sheetHeight: CGFloat = 360
    @State var purchasesSuccessScale: CGFloat = 0.3
    @State var purchaseFailScale: CGFloat = 0.3
    let sheetHeightRatio: CGFloat = 0.43
    
    var shouldApplyBlur: Bool {
        showPurchaseFailAlert || showPurchaseSuccessAlert || isCapturing || !isSceneReady || bundleVM.isPurchasing
    }
    
    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                mainContentView

                // 배경, 카라비너 선택 시트
                selectItemSheetContent
            }
            .blur(radius: shouldApplyBlur ? 15 : 0)
            
            loadingOverlay
            
            alertContent
                .position(x: screenWidth / 2, y: screenHeight / 2)
        }
        .sheet(isPresented: $showPurchaseSheet) {
            purchaseSheetView
        }
        .sheet(isPresented: $showSelectKeyringSheet) {
            keyringSheetContent
        }
        .sheet(isPresented: $bundleVM.showSheetSortSheet) {
            WorkshopSortSheet(
                showSheet: $bundleVM.showSheetSortSheet,
                sortOrder: $bundleVM.sheetSortOrder
            )
        }
        .navigationBarBackButtonHidden()
        .withToast(position: .default)
        .task {
            // 화면 전환 중이면 초기화 건너뛰기
            guard !isNavigatingAway else {
                return
            }
            await initializeData()
        }
        .onAppear {
            // 화면이 나타날 때마다 데이터 새로고침
            Task {
                await bundleVM.refreshEditData()
            }
            TabBarManager.hide()
            bundleVM.resetSheetFilterState()
            // 화면 첫 진입 시 배경 시트를 보여줌
            if !showItemSheet {
                isBackgroundMode = true
                showItemSheet = true
            }
        }
        .onDisappear {
            isNavigatingAway = false
            // 편집 화면 나갈 때 상태 초기화
            bundleVM.resetEditState()
        }
        .ignoresSafeArea()
        .onChange(of: bundleVM.newSelectedBackground) { _, newBackground in
            guard newBackground != nil else { return }
            // 배경 변경 시에는 키링 데이터 업데이트만 수행 (Firebase 접근 없음)
            updateKeyringDataList()
        }
        .onChange(of: bundleVM.newSelectedCarabiner) { _, newCarabiner in
            guard newCarabiner != nil else { return }
            // 카라비너 변경 시에는 키링 데이터 업데이트만 수행 (Firebase 접근 없음)
            updateKeyringDataList()
        }
    }
    
    // MARK: - Main Content Views
    
    /// 메인 콘텐츠 영역 (배경, 씬, 네비게이션 바)
    private var mainContentView: some View {
        ZStack {
            if let bundle = bundleVM.selectedBundle,
               let background = bundleVM.newSelectedBackground,
               let carabiner = bundleVM.newSelectedCarabiner {
                
                keyringEditSceneView(bundle: bundle, background: background, carabiner: carabiner)
                
            } else {
                ZStack {
                    if let bg = bundleVM.newSelectedBackground {
                        LazyImage(url: URL(string: bg.background.backgroundImage)) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .scaledToFit()
                            } else if state.isLoading {
                                Color.black20
                                    .ignoresSafeArea()
                            }
                        }
                    }
                    if let cb = bundleVM.newSelectedCarabiner {
                        VStack {
                            LazyImage(url: URL(string: cb.carabiner.carabinerImage[0])) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            
            // navigationBar
            customNavigationBar
        }
    }
    
    // MARK: - 키링 편집 씬 뷰
    private func keyringEditSceneView(bundle: KeyringBundle, background: BackgroundViewData, carabiner: CarabinerViewData) -> some View {
        ZStack(alignment: .top) {
            // MultiKeyringScene
            MultiKeyringSceneView(
                keyringDataList: keyringDataList,
                ringType: .basic,
                chainType: .basic,
                backgroundColor: .clear,
                backgroundImageURL: background.background.backgroundImage,
                carabinerBackImageURL: carabiner.carabiner.backImageURL,
                carabinerFrontImageURL: carabiner.carabiner.frontImageURL,
                carabinerId: carabiner.carabiner.id ?? "",
                carabinerX: carabiner.carabiner.carabinerX,
                carabinerY: carabiner.carabiner.carabinerY,
                carabinerWidth: carabiner.carabiner.carabinerWidth,
                currentCarabinerType: carabiner.carabiner.type,
                onAllKeyringsReady: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isSceneReady = true
                    }
                }
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: isSceneReady)
            .id("scene_\(background.background.id ?? "bg")_\(carabiner.carabiner.id ?? "cb")_\(keyringDataList.count)_\(sceneRefreshId.uuidString)")
            
            // 키링 추가 버튼들
            GeometryReader { geometry in
                let sceneWidth: CGFloat = 402
                let sceneHeight: CGFloat = 874
                
                // 실제 화면 크기에 맞게 씬을 스케일링 하는 비율 계산
                let scale = max(geometry.size.width / sceneWidth, geometry.size.height / sceneHeight)
                
                // 스케일 적용 후 콘텐츠 크기
                let contentW = sceneWidth * scale
                let contentH = sceneHeight * scale
                
                // 씬을 화면 중앙에 배치하기 위한 오프셋 (실제 뷰 크기와 스케일 된 씬의 크기 차이를 균등하게 배분)
                let dx = (geometry.size.width - contentW) / 2
                let dy = (geometry.size.height - contentH) / 2
                
                ForEach(0..<carabiner.carabiner.maxKeyringCount, id: \.self) { index in
                    // 씬 좌표를 실제 화면 좌표로 변환 (오프셋 + 스케일 적용)
                    let viewX = dx + carabiner.carabiner.keyringXPosition[index] * scale
                    let viewY = dy + carabiner.carabiner.keyringYPosition[index] * scale
                    
                    AddKeyringButton(
                        isSelected: selectedPosition == index,
                        action: {
                            selectedPosition = index
                            withAnimation(.easeInOut) {
                                showSelectKeyringSheet = true
                            }
                        }
                    )
                    .position(x: viewX, y: viewY)
                    .opacity(showSelectKeyringSheet && selectedPosition != index ? 0.3 : 1.0)
                    .zIndex(selectedPosition == index ? 100 : 1) // 선택된 버튼이 dim 오버레이(zIndex 1) 위로 오도록
                    .opacity(isSceneReady ? 1.0 : 0.0) // LoadingAlert가 표시될 때는 버튼 숨김
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

// MARK: - 툴바
extension BundleEditView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                bundleVM.lastBackgroundIdForDetail = ""
                bundleVM.lastCarabinerIdForDetail = ""
                bundleVM.lastKeyringsIdForDetail = ""
                
                isNavigatingAway = true
                router.pop()
            }
        } center: {
        } trailing: {
            if bundleVM.hasUnpurchasedItems {
                PurchaseToolbarButton(title: "구매 \(bundleVM.payableItemsCount)") {
                    showPurchaseSheet = true
                }
            } else {
                TextToolbarButton(title: "완료") {
                    // 네트워크 체크
                    guard NetworkManager.shared.isConnected else {
                        ToastManager.shared.show()
                        return
                    }
                    
                    Task {
                        await MainActor.run {
                            // pop 전에 현재 구성 id를 ViewModel에 저장
                            let bgId = bundleVM.makeBackgroundId(bundleVM.newSelectedBackground?.background ?? bundleVM.resolveBackground(from: bundleVM.selectedBundle?.selectedBackground ?? ""))
                            let cbId = bundleVM.makeCarabinerId(bundleVM.newSelectedCarabiner?.carabiner ?? bundleVM.resolveCarabiner(from: bundleVM.selectedBundle?.selectedCarabiner ?? ""))
                            
                            // 편집 중 키링 데이터 기준으로 keyringsId 생성
                            let currentKeyringDataList = keyringDataList
                            let krId = bundleVM.makeKeyringsId(currentKeyringDataList)
                            
                            bundleVM.returnBackgroundId = bgId
                            bundleVM.returnCarabinerId = cbId
                            bundleVM.returnKeyringsId = krId
                            
                            // 화면 전환 시작 플래그
                            isNavigatingAway = true
                        }
                        
                        // 상태 변경이 UI에 반영되도록 짧은 대기
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
                        await bundleVM.saveBundleChanges()
                        
                        // 저장 후 썸네일 재캡쳐, 캐시 저장
                        if let bundle = bundleVM.selectedBundle, let documentId = bundleVM.selectedBundle?.documentId {
                            await recaptureAndCacheBundleThumbnail(bundleId: documentId, bundleName: bundle.name, createdAt: bundle.createdAt)
                        }
                        
                        await MainActor.run {
                            router.pop()
                        }
                    }
                }
            }
        }
    }
}
