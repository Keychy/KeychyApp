//
//  BundleCreateView.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//
// Extension 파일:
//   +SelectSheet    - 시트 컨텐츠 (배경/카라비너/키링)
//   +Alert          - 알럿 뷰
//   +Purchase       - 구매 시트, 구매 로직
//   +Initialization - 데이터 로딩
//   +Capture        - 씬 캡처

import SwiftUI
import NukeUI
import SceneKit
import FirebaseFirestore

struct BundleCreateView<Route: BundleRoute>: View {

    // MARK: - 프로퍼티들
    @Bindable var router: NavigationRouter<Route>
    @State var collectionVM: CollectionViewModel
    @Bindable var bundleVM: BundleViewModel

    // 시트 활성화 상태
    @Namespace var sheetButtonNamespace
    @State var showItemSheet: Bool = false
    @State var isBackgroundMode: Bool = true  // true: 배경, false: 카라비너
    @State var showKeyringSheet: Bool = false

    // 시트 높이 (DraggableSheet.onAppear에서 mediumHeight로 갱신됨)
    @State var sheetHeight: CGFloat = UIScreen.main.bounds.height * 0.4

    // 키링 선택 상태
    @State var selectedKeyrings: [Int: Keyring] = [:]
    @State var keyringOrder: [Int] = []
    @State var selectedPosition: Int = 0
    @State var keyringSearchText: String = ""

    // 캡처 상태
    @State var isCapturing: Bool = false
    @State var sceneRefreshId = UUID()
    @State var isSceneReady: Bool = false

    // 구매 시트
    @State var showPurchaseSheet = false

    // 구매 Alert 애니메이션
    @State var showPurchaseSuccessAlert = false
    @State var purchasesSuccessScale: CGFloat = 0.3
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3

    // 공통 그리드 컬럼 (배경, 카라비너, 키링 모두 동일)
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    let sheetHeightRatio: CGFloat = 0.5

    // MARK: - 메인 뷰
    var body: some View {
        ZStack(alignment: .bottom) {
            if let bg = bundleVM.newSelectedBackground,
               let cb = bundleVM.newSelectedCarabiner {
                // 배경 + 카라비너 + 키링 씬
                ZStack {
                    MultiKeyringSceneView(
                        keyringDataList: createKeyringDataList(carabiner: cb.carabiner),
                        ringType: .basic,
                        chainType: .basic,
                        backgroundColor: .clear,
                        backgroundImageURL: bg.background.backgroundImage,
                        backgroundLottieId: bg.background.isLottie ? bg.background.id : nil,
                        carabinerBackImageURL: cb.carabiner.backImageURL,
                        carabinerFrontImageURL: cb.carabiner.frontImageURL,
                        carabinerLottieId: cb.carabiner.isLottie ? cb.carabiner.id : nil,
                        carabinerId: cb.carabiner.id ?? "",
                        carabinerX: cb.carabiner.carabinerX,
                        carabinerY: cb.carabiner.carabinerY,
                        carabinerWidth: cb.carabiner.carabinerWidth,
                        currentCarabinerType: cb.carabiner.type,
                        cleanupOnDisappear: true,
                        onAllKeyringsReady: {
                            // onSetupComplete에서 호출됨
                            // (카라비너 Lottie 프리렌더링 + 키링 로드 + 물리 활성화 후)
                            withAnimation(.easeOut(duration: 0.3)) {
                                isSceneReady = true
                            }
                        }
                    )
                    .id("scene_\(cb.carabiner.id ?? "cb")_\(selectedKeyrings.count)_\(sceneRefreshId.uuidString)")

                    // 키링 추가 + 버튼들
                    keyringButtons(carabiner: cb.carabiner)
                }
                .blur(radius: showPurchaseSuccessAlert || isCapturing ? 10 : 0)
                .onTapGesture {
                    if showItemSheet { showItemSheet = false }
                }

                // 하단 셀렉터 + 시트
                sheetContent
                    .blur(radius: showPurchaseSuccessAlert || isCapturing ? 10 : 0)

                customNavigationBar
                    .blur(radius: showPurchaseSuccessAlert || isCapturing ? 10 : 0)
            }

            // Lottie 씬 로딩 중 (시트 포함 전체 차단)
            if !isSceneReady {
                Color.black20
                    .ignoresSafeArea()
                LoadingAlert(type: .longWithKeychy, message: "아이템을 불러오고 있어요")
            }

            // 캡처 중 로딩
            if isCapturing {
                Color.black20
                    .ignoresSafeArea()
                LoadingAlert(type: .longWithKeychy, message: "뭉치 만드는 중...")
            }

            // Alert들
            alertContent
                .position(x: screenWidth / 2, y: screenHeight / 2)

        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .task {
            await initializeData()
        }
        .onAppear {
            Task {
                await refreshData()
            }
            TabBarManager.hide()
            bundleVM.resetSheetFilterState()
        }
        .onDisappear {
            bundleVM.resetEditState()
        }
        .sheet(isPresented: $showPurchaseSheet) {
            purchaseSheetView
        }
        .sheet(isPresented: $showKeyringSheet) {
            keyringSheetContent
        }
        .sheet(isPresented: $bundleVM.showSheetSortSheet) {
            sortSheetContent
        }
    }

    /// 정렬 선택 시트
    private var sortSheetContent: some View {
        WorkshopSortSheet(
            showSheet: $bundleVM.showSheetSortSheet,
            sortOrder: $bundleVM.sheetSortOrder
        )
    }
}

// MARK: - 커스텀 네비게이션 바
extension BundleCreateView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                bundleVM.restoreMainBundle()
                TabBarManager.show()
                router.pop()
            }
        } center: {
        } trailing: {
            if bundleVM.hasUnpurchasedItems {
                PurchaseToolbarButton(title: "구매 \(bundleVM.payableItemsCount)") {
                    showPurchaseSheet = true
                }
            } else {
                Button {
                    Task {
                        await captureAndSaveScene()
                    }
                } label: {
                    Text("다음")
                        .typography(.suit17B)
                        .padding(4)
                        .foregroundStyle(isCapturing || selectedKeyrings.isEmpty ? .gray300 : .main500)
                }
                .frame(width: 62, height: 44)
                .glassEffect(.regular.interactive(), in: .capsule)
                .disabled(isCapturing || selectedKeyrings.isEmpty)
            }
        }
    }
}
