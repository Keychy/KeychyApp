//
//  BundleCreateView.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI
import NukeUI
import SceneKit
import FirebaseFirestore

struct BundleCreateView<Route: BundleRoute>: View {
    
    //MARK: - 프로퍼티들
    @Bindable var router: NavigationRouter<Route>
    @State var collectionVM: CollectionViewModel
    @Bindable var bundleVM: BundleViewModel

    // 시트 활성화 상태
    @State private var showItemSheet: Bool = false
    @State private var isBackgroundMode: Bool = true  // true: 배경, false: 카라비너
    @State private var showKeyringSheet: Bool = false

    // 시트 높이
    @State private var sheetHeight: CGFloat = 360

    // 키링 선택 상태
    @State private var selectedKeyrings: [Int: Keyring] = [:]
    @State private var keyringOrder: [Int] = []
    @State private var selectedPosition: Int = 0

    // 캡처 상태
    @State private var isCapturing: Bool = false
    @State private var sceneRefreshId = UUID()
    @State private var isSceneReady: Bool = false

    // 구매 시트
    @State var showPurchaseSheet = false

    // 구매 Alert 애니메이션
    @State var showPurchaseSuccessAlert = false
    @State var purchasesSuccessScale: CGFloat = 0.3
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3

    // 공통 그리드 컬럼 (배경, 카라비너, 키링 모두 동일)
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private let sheetHeightRatio: CGFloat = 0.5
    
    //MARK: 메인 뷰
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
                        carabinerBackImageURL: cb.carabiner.backImageURL,
                        carabinerFrontImageURL: cb.carabiner.frontImageURL,
                        carabinerX: cb.carabiner.carabinerX,
                        carabinerY: cb.carabiner.carabinerY,
                        carabinerWidth: cb.carabiner.carabinerWidth,
                        currentCarabinerType: cb.carabiner.type,
                        onBackgroundLoaded: {
                            // 키링이 없으면 배경 로드 시 바로 준비 완료
                            if selectedKeyrings.isEmpty {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isSceneReady = true
                                }
                            }
                        },
                        onAllKeyringsReady: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isSceneReady = true
                            }
                        }
                    )
                    .id("scene_\(bg.background.id ?? "bg")_\(cb.carabiner.id ?? "cb")_\(selectedKeyrings.count)_\(sceneRefreshId.uuidString)")

                    // 키링 추가 + 버튼들
                    keyringButtons(carabiner: cb.carabiner)
                }
                .blur(radius: showPurchaseSuccessAlert || isCapturing ? 10 : 0)

                // 하단 셀렉터 + 시트
                sheetContent
                    .blur(radius: showPurchaseSuccessAlert || isCapturing ? 10 : 0)

                customNavigationBar
                    .blur(radius: showPurchaseSuccessAlert || isCapturing ? 10 : 0)
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

            // 구매 시트 오버레이
            ZStack {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(10)
                VStack {
                    Spacer()
                    purchaseSheetView
                }
                .zIndex(100)
                .ignoresSafeArea()
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: showPurchaseSheet)
            }
            .opacity(showPurchaseSheet ? 1 : 0)
            .blur(radius: showPurchaseSuccessAlert ? 10 : 0)
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
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
        } trailing: {
            if bundleVM.hasUnpurchasedItems {
                PurchaseToolbarButton(title: "구매 \(bundleVM.payableItemsCount)") {
                    showPurchaseSheet = true
                }
            } else {
                NextToolbarButton(isDisabled: isCapturing || selectedKeyrings.isEmpty) {
                    Task {
                        await captureAndSaveScene()
                    }
                }
            }
        }
    }
}


// MARK: - 키링 + 버튼
extension BundleCreateView {
    private func keyringButtons(carabiner: Carabiner) -> some View {
        GeometryReader { geometry in
            let sceneWidth: CGFloat = 402
            let sceneHeight: CGFloat = 874
            let scale = max(geometry.size.width / sceneWidth, geometry.size.height / sceneHeight)

            let contentW = sceneWidth * scale
            let contentH = sceneHeight * scale

            let dx = (geometry.size.width - contentW) / 2
            let dy = (geometry.size.height - contentH) / 2

            ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
                let viewX = dx + carabiner.keyringXPosition[index] * scale
                let viewY = dy + carabiner.keyringYPosition[index] * scale

                AddKeyringButton(
                    isSelected: selectedPosition == index,
                    action: {
                        selectedPosition = index
                        showKeyringSheet = true
                    }
                )
                .position(x: viewX, y: viewY)
                .opacity(isSceneReady ? 1.0 : 0.0)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 하단 시트
extension BundleCreateView {
    private var sheetContent: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            if showItemSheet {
                // 시트가 있을 때: 셀렉터 + 시트가 함께 움직임
                VStack(spacing: 0) {
                    BundleSheetToggleButtons(
                        showItemSheet: $showItemSheet,
                        isBackgroundMode: $isBackgroundMode
                    )
                    .padding(.bottom, 10)

                    DraggableSheet(
                        sheetHeight: $sheetHeight,
                        header: BundleSheetFilterBar(viewModel: bundleVM),
                        content: itemSheetContent,
                        onDismiss: {
                            showItemSheet = false
                        }
                    )
                }
                .transition(.move(edge: .bottom))
            } else {
                // 시트가 없을 때: 셀렉터만 하단에 고정
                BundleSheetToggleButtons(
                    showItemSheet: $showItemSheet,
                    isBackgroundMode: $isBackgroundMode
                )
                .padding(.bottom, 50)
                .transition(.identity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showItemSheet)
    }

    @ViewBuilder
    private var itemSheetContent: some View {
        if isBackgroundMode {
            SelectBackgroundSheet(
                viewModel: bundleVM,
                selectedBG: bundleVM.newSelectedBackground,
                onBackgroundTap: { bg in
                    bundleVM.newSelectedBackground = bg
                }
            )
        } else {
            SelectCarabinerSheet(
                viewModel: bundleVM,
                selectedCarabiner: bundleVM.newSelectedCarabiner,
                onCarabinerTap: { carabiner in
                    bundleVM.newSelectedCarabiner = carabiner
                }
            )
        }
    }

    private var keyringSheetContent: some View {
        VStack(spacing: 18) {
            Text("키링 선택")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.top, 20)

            if bundleVM.keyring.isEmpty {
                VStack {
                    Image(.emptyViewIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 77)
                    Text("공방에서 키링을 만들 수 있어요")
                        .typography(.suit15R)
                        .foregroundStyle(.black100)
                        .padding(.vertical, 15)
                }
                .padding(.bottom, 77)
                .padding(.top, 62)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(bundleVM.sortedKeyringsForSelection(selectedKeyrings: selectedKeyrings, selectedPosition: selectedPosition), id: \.self) { keyring in
                            keyringCell(keyring: keyring)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .presentationDetents([.fraction(0.45), .fraction(0.85)])
        .presentationDragIndicator(.visible)
    }

    private func keyringCell(keyring: Keyring) -> some View {
        let isSelectedHere = selectedKeyrings[selectedPosition]?.id == keyring.id
        let isSelectedElsewhere = selectedKeyrings.values.contains { $0.id == keyring.id } && !isSelectedHere

        return Button {
            if isSelectedHere {
                selectedKeyrings[selectedPosition] = nil
                keyringOrder.removeAll { $0 == selectedPosition }
            } else if !isSelectedElsewhere {
                if selectedKeyrings[selectedPosition] != nil {
                    keyringOrder.removeAll { $0 == selectedPosition }
                }
                selectedKeyrings[selectedPosition] = keyring
                keyringOrder.append(selectedPosition)
                showKeyringSheet = false
            }
            sceneRefreshId = UUID()
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    ZStack {
                        CollectionCellView(keyring: keyring)
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                            .cornerRadius(10)

                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelectedHere ? .mainOpacity80 : .clear, lineWidth: 1.8)
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)

                        if isSelectedElsewhere {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.black50)
                                .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                        }
                    }

                    Text(keyring.name)
                        .typography(isSelectedHere ? .notosans14SB : .notosans14M)
                        .foregroundStyle(isSelectedHere ? .main500 : .black100)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if isSelectedElsewhere || isSelectedHere {
                    Text("장착 중")
                        .foregroundStyle(.white100)
                        .typography(.suit13M)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 20).fill(.mainOpacity80))
                        .padding(.top, 5)
                        .padding(.trailing, 5)
                }
            }
        }
        .disabled(keyring.status == .packaged || keyring.status == .published || isSelectedElsewhere)
    }
}



// MARK: - 데이터 가져오는 메서드
extension BundleCreateView {
    
    /// 초기 데이터 로딩
    private func initializeData() async {
        // 사용자가 소유한 배경과 카라비너 데이터를 가져옴
        await loadUserOwnedItems()
    }
    
    /// 화면이 다시 나타날 때 데이터 새로고침
    private func refreshData() async {
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
    private func loadUserOwnedItems() async {
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

// MARK: - Alert 컨텐츠
extension BundleCreateView {
    private var alertContent: some View {
        ZStack {
            // 구매 성공 Alert
            if showPurchaseSuccessAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        showPurchaseSuccessAlert = false
                        purchasesSuccessScale = 0.3
                    }

                KeychyAlert(type: .checkmark, message: "구매가 완료되었어요!", isPresented: $showPurchaseSuccessAlert)
                    .zIndex(101)
            }

            // 구매 실패 Alert
            if showPurchaseFailAlert {
                ZStack {
                    Color.black20
                        .ignoresSafeArea()
                        .onTapGesture {
                            showPurchaseFailAlert = false
                            purchaseFailScale = 0.3
                        }

                    PurchaseFailAlert(
                        checkmarkScale: purchaseFailScale,
                        onCancel: {
                            showPurchaseFailAlert = false
                            purchaseFailScale = 0.3
                        },
                        onCharge: {
                            showPurchaseFailAlert = false
                            purchaseFailScale = 0.3
                            bundleVM.saveCurrentSelection()
                            router.push(.coinCharge)
                        }
                    )
                    .padding(.horizontal, 51)
                }
            }
        }
    }
}

// MARK: - 구매 시트 뷰
extension BundleCreateView {
    private var purchaseSheetView: some View {
        VStack(spacing: 12) {
            // 상단 섹션 - 닫기 버튼, 타이틀
            HStack {
                Button {
                    showPurchaseSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray600)
                }
                Spacer()
                Text("구매하기")
                    .typography(.suit17B)
                    .foregroundStyle(.gray600)
                Spacer()
            }
            .padding(EdgeInsets(top: 30, leading: 20, bottom: 10, trailing: 20))
            
            // 구매할 아이템 목록
            VStack(spacing: 20) {
                if let bg = bundleVM.newSelectedBackground, !bg.isOwned && bg.background.price > 0 {
                    BundlePurchaseCartItem(
                        imageURL: bg.background.backgroundImage,
                        name: bg.background.backgroundName,
                        type: "배경",
                        price: bg.background.price
                    )
                }
                if let cb = bundleVM.newSelectedCarabiner, !cb.isOwned && cb.carabiner.price > 0 {
                    BundlePurchaseCartItem(
                        imageURL: cb.carabiner.carabinerImage.first ?? "",
                        name: cb.carabiner.carabinerName,
                        type: "카라비너",
                        price: cb.carabiner.price
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            
            // 내 보유 재화와 총 가격
            HStack(spacing: 6) {
                Text("내 보유 : ")
                    .typography(.suit15M25)
                    .foregroundStyle(.black100)
                    .padding(.vertical, 4.5)
                Text("\(UserManager.shared.currentUser?.coin ?? 0)")
                    .typography(.nanum16EB)
                    .foregroundStyle(.main500)
            }
            purchaseButton
                .padding(.horizontal, 33.2)
                .padding(.bottom, 40)
                .adaptiveBottomPadding()
        }
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38)
                .fill(.white100)
        )
    }
    
    // 구매 버튼
    private var purchaseButton: some View {
        Button {
            Task {
                await purchaseItems()
            }
        } label: {
            HStack(spacing: 5) {
                if bundleVM.isPurchasing {
                    LoadingAlert(type: .short40, message: nil)
                } else {
                    Image(.myCoinMini)
                }

                Text("\(bundleVM.totalCartPrice)")
                    .typography(.nanum18EB)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Text("(\(bundleVM.payableItemsCount)개)")
                    .typography(.suit17SB)
            }
            .foregroundStyle(.white100)
            .frame(maxWidth: .infinity)
            .background(bundleVM.isPurchasing ? .gray400 : .black80)
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
        .disabled(bundleVM.isPurchasing)
    }

    // MARK: - 구매 처리
    private func purchaseItems() async {
        let result = await bundleVM.purchaseSelectedItems()

        switch result {
        case .success:
            // 모든 구매 성공
            await refreshData()

            await MainActor.run {
                // ViewModel 상태 동기화
                if let bg = bundleVM.newSelectedBackground {
                    bundleVM.selectedBackground = bg.background
                }
                if let cb = bundleVM.newSelectedCarabiner {
                    bundleVM.selectedCarabiner = cb.carabiner
                }

                showPurchaseSheet = false
                showPurchaseSuccessAlert = true
                purchasesSuccessScale = 0.3
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchasesSuccessScale = 1.0
                }
            }

            // 2.5초 후 알럿 자동 닫기 (Alert duration 2초 + 0.5초 여유)
            try? await Task.sleep(for: .seconds(2.5))

            await MainActor.run {
                showPurchaseSuccessAlert = false
                purchasesSuccessScale = 0.3
            }

        case .insufficientCoins, .failed:
            // 구매 실패
            await MainActor.run {
                showPurchaseSheet = false
            }

            // 시트 닫히는 애니메이션 대기
            try? await Task.sleep(for: .seconds(0.3))

            await MainActor.run {
                showPurchaseFailAlert = true
                purchaseFailScale = 0.3
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseFailScale = 1.0
                }
            }
        }
    }
}

// MARK: - 키링 데이터 및 캡처
extension BundleCreateView {
    /// 키링 데이터 리스트 생성 (씬 표시용)
    private func createKeyringDataList(carabiner: Carabiner) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        for index in keyringOrder {
            guard let keyring = selectedKeyrings[index] else { continue }
            let soundId = keyring.soundId

            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()

            let particleId = keyring.particleId
            let position = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )

            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: position,
                bodyImageURL: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: particleId,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength
            )
            dataList.append(data)
        }

        return dataList
    }

    /// 씬 캡처 및 저장
    private func captureAndSaveScene() async {
        guard let cb = bundleVM.newSelectedCarabiner,
              let bg = bundleVM.newSelectedBackground else {
            return
        }

        let carabiner = cb.carabiner
        let background = bg.background

        // 캡처 시작
        await MainActor.run {
            isCapturing = true
            bundleVM.selectedKeyringsForBundle = selectedKeyrings
            bundleVM.selectedBackground = background
            bundleVM.selectedCarabiner = carabiner
        }

        // 배경 이미지 미리 로드
        guard let _ = try? await StorageManager.shared.getImage(path: background.backgroundImage) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }

        // 캡처용 키링 데이터 생성
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []

        for (index, keyring) in selectedKeyrings.sorted(by: { $0.key < $1.key }) {
            let data = MultiKeyringCaptureScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyring.bodyImage,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength
            )
            keyringDataList.append(data)
        }

        // 카라비너 이미지 추출
        let carabinerType = CarabinerType.from(carabiner.carabinerType)
        let carabinerBackURL: String?
        let carabinerFrontURL: String?

        if carabinerType == .hamburger {
            carabinerBackURL = carabiner.carabinerImage[1]
            carabinerFrontURL = carabiner.carabinerImage[2]
        } else {
            carabinerBackURL = carabiner.carabinerImage[0]
            carabinerFrontURL = nil
        }

        // 씬 캡처
        if let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: background.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerX: carabiner.carabinerX,
            carabinerY: carabiner.carabinerY,
            carabinerWidth: carabiner.carabinerWidth
        ) {
            await MainActor.run {
                bundleVM.bundleCapturedImage = pngData
            }
        }

        // 캡처 완료 후 다음 화면으로 이동
        await MainActor.run {
            isCapturing = false
            router.push(.bundleNameInputView)
        }
    }
}

