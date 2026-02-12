//
//  BundleCompleteView.swift
//  Keychy
//
//  Created by 길지훈 on 2/7/26.
//
//  뭉치 완성 화면
//  - 뭉치 생성 완료 후 표시되는 완성뷰

import SwiftUI
import SpriteKit

struct BundleCompleteView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var collectionVM: CollectionViewModel
    @Bindable var bundleVM: BundleViewModel


    // MARK: - Video Generation
    @State var videoGenerator = BundleVideoGenerator()
    @State var isGeneratingVideo = false
    @State var cachedVideoURL: URL?
    @State var showShareSheet = false

    // MARK: - Image Capture
    @State var isCapturing = false
    @State var showImageSaved = false
    @State var showVideoSaved = false

    // MARK: - Main Bundle Setting
    @State var showSetMainAlert = false
    @State var showMainChanged = false
    @State var showAlreadyMainToast = false

    // MARK: - Scene
    @State var isInteractionEnabled = false
    @State var isSceneReady = false
    @State var keyringDataList: [MultiKeyringScene.KeyringData] = []

    var body: some View {
        ZStack {
            // 1. 메인 씬 (배경 포함) - blur 적용
            sceneContent
                .blur(radius: isAlertShowing ? 15 : 0)

            // 2. 하단 정보 + 버튼 오버레이 - blur 적용
            VStack {
                Spacer()
                bottomOverlay
                    .cinematicAppear(delay: 0.6, duration: 0.8, style: .slideUp)
            }
            .padding(.bottom, 40)
            .blur(radius: isAlertShowing ? 15 : 0)

            // 3. Alerts 오버레이 - blur 없음
            alertsOverlay

            // 4. 로딩 오버레이
            loadingOverlay
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .toolbar {
            closeToolbarItem
            titleToolbarItem
            inventoryToolbarItem
        }
        .withToast(position: .default)
        .sheet(isPresented: $showShareSheet) {
            if let url = cachedVideoURL {
                ShareSheet(items: [url])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .task {
            await loadBundleData()
        }
    }
}

// MARK: - Scene Content
extension BundleCompleteView {
    /// 메인 씬 (배경 + 카라비너 + 키링)
    @ViewBuilder
    private var sceneContent: some View {
        if let carabiner = bundleVM.selectedCarabiner,
           let background = bundleVM.selectedBackground {

            MultiKeyringSceneView(
                keyringDataList: keyringDataList,
                ringType: .basic,
                chainType: .basic,
                backgroundColor: .clear,
                backgroundImageURL: background.backgroundImage,
                backgroundLottieId: background.isLottie ? background.id : nil,
                carabinerBackImageURL: carabiner.backImageURL,
                carabinerFrontImageURL: carabiner.frontImageURL,
                carabinerLottieId: carabiner.isLottie ? carabiner.id : nil,
                carabinerId: carabiner.id ?? "",
                carabinerX: carabiner.carabinerX,
                carabinerY: carabiner.carabinerY,
                carabinerWidth: carabiner.carabinerWidth,
                currentCarabinerType: carabiner.type,
                cleanupOnDisappear: true,
                onAllKeyringsReady: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isSceneReady = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isInteractionEnabled = true
                        }
                    }
                }
            )
            .allowsHitTesting(isInteractionEnabled)
            .id("scene_\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map { "\($0.index)_\($0.bodyImageURL.hashValue)" }.joined(separator: "_"))")
        }
    }

    /// 로딩 오버레이
    @ViewBuilder
    private var loadingOverlay: some View {
        if !isSceneReady {
            Color.black20
                .ignoresSafeArea()

            LoadingAlert(type: .longWithKeychy, message: "뭉치를 불러오고 있어요")
        }

        if isGeneratingVideo {
            Color.black20
                .ignoresSafeArea()

            LoadingAlert(type: .longWithKeychy, message: "공유할 영상을 만들고 있어요!")
        }
    }

    /// 뭉치 데이터 로드 - BundleCreateView에서 이미 설정된 데이터 사용
    @MainActor
    private func loadBundleData() async {
        guard let carabiner = bundleVM.selectedCarabiner else {
            isSceneReady = true
            return
        }

        // BundleCreateView에서 설정한 selectedKeyringsForBundle 사용
        let selectedKeyrings = bundleVM.selectedKeyringsForBundle

        // 키링 데이터 생성 (Firebase 호출 없이 로컬 데이터 사용)
        var dataList: [MultiKeyringScene.KeyringData] = []

        for (index, keyring) in selectedKeyrings.sorted(by: { $0.key < $1.key }) {
            guard index < carabiner.maxKeyringCount else { continue }

            let soundId = keyring.soundId
            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()

            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: keyring.particleId,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength
            )
            dataList.append(data)
        }

        keyringDataList = dataList

        // 키링이 없으면 바로 준비 완료
        if dataList.isEmpty {
            isSceneReady = true
        }
    }
}

// MARK: - Bottom Overlay (정보 + 버튼)
extension BundleCompleteView {
    private var bottomOverlay: some View {
        VStack(spacing: 20) {
            // 뭉치 정보
            bundleInfo

            // 액션 버튼
            actionButtons
                .opacity(isCapturing ? 0 : 1)
        }
    }

    private var bundleInfo: some View {
        VStack(spacing: 0) {
            if let bundle = bundleVM.selectedBundle {
                Text(bundle.name)
                    .typography(.malang26B)
                    .foregroundStyle(.black100)
                    .padding(.bottom, 2)

                Text(formattedDate(date: bundle.createdAt))
                    .typography(.suit14M)
                    .foregroundStyle(.black100)
            }
        }
    }

    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
}

// MARK: - Action Buttons
extension BundleCompleteView {
    private func actionButton(
        image: ImageResource,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(image)
                Text(title)
                    .typography(.suit12M)
                    .foregroundStyle(.black100)
            }
            .frame(width: 74, height: 47)
            .padding(.vertical, 11.5)
            .padding(.horizontal, 8)
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
    }

    private var actionButtons: some View {
        HStack(spacing: 17) {
            // 이미지 저장
            actionButton(image: .saveBlack, title: "이미지 저장") {
                captureAndSaveImage()
            }

            // 공유
            actionButton(image: .share, title: "공유") {
                if cachedVideoURL != nil {
                    showShareSheet = true
                    return
                }
                Task {
                    await generateVideoForShare()
                }
            }

            // 대표로 설정
            actionButton(image: .starFill, title: "대표로 설정") {
                handleSetMainButtonTap()
            }
        }
    }
}

// MARK: - Toolbar Items
extension BundleCompleteView {
    private var isAlertShowing: Bool {
        showImageSaved || showVideoSaved || isGeneratingVideo ||
        showSetMainAlert || showMainChanged || showAlreadyMainToast || !isSceneReady
    }

    var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                cleanupCachedVideo()
                bundleVM.restoreMainBundle()
                TabBarManager.switchTo(.workshop)
                TabBarManager.show()
                router.reset()
            } label: {
                Image(.dismissGray600)
            }
            .opacity(isAlertShowing ? 0 : 1)
            .allowsHitTesting(!isAlertShowing)
        }
        .sharedBackgroundVisibility(isAlertShowing ? .hidden : .visible)
    }

    var titleToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("뭉치 완성!")
                .typography(.notosans17M)
                .foregroundStyle(.black100)
                .opacity(isAlertShowing ? 0 : 1)
        }
    }

    var inventoryToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                navigateToInventory()
            } label: {
                Image(.goToCollection)
            }
            .opacity(isAlertShowing ? 0 : 1)
            .allowsHitTesting(!isAlertShowing)
        }
        .sharedBackgroundVisibility(isAlertShowing ? .hidden : .visible)
    }

    private func navigateToInventory() {
        cleanupCachedVideo()
        bundleVM.restoreMainBundle()
        CollectionViewModel.shouldStartWithBundleTab = true
        TabBarManager.switchTo(.collection)
        TabBarManager.show()
        router.reset()
    }
}

// MARK: - Alerts
extension BundleCompleteView {
    @ViewBuilder
    private var alertsOverlay: some View {
        KeychyAlert(
            type: .imageSave,
            message: "이미지가 저장되었어요!",
            isPresented: $showImageSaved
        )

        KeychyAlert(
            type: .imageSave,
            message: "영상이 저장되었어요!",
            isPresented: $showVideoSaved
        )

        KeychyAlert(
            type: .checkmark,
            message: "대표 뭉치가 변경되었어요!",
            isPresented: $showMainChanged
        )

        // 이미 대표 뭉치 토스트
        if showAlreadyMainToast {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)

            Text("이미 대표 뭉치로 설정되어 있어요")
                .typography(.suit17SB)
                .foregroundColor(.black100)
                .frame(maxWidth: .infinity)
                .frame(height: 73)
                .padding(.horizontal, 51)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
                .zIndex(100)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showAlreadyMainToast = false
                        }
                    }
                }
        }

        // 대표 설정 확인 팝업
        if showSetMainAlert {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)

            setMainAlertView
                .zIndex(100)
        }
    }

    private var setMainAlertView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image(.bangMark)
                    .padding(.vertical, 4)

                Text("대표 뭉치로 설정할까요?")
                    .typography(.suit20B)
                    .foregroundStyle(.black100)
                Text("선택한 뭉치가 홈에 걸려요.")
                    .typography(.suit15R)
                    .foregroundStyle(.black100)
            }
            .padding(8)

            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSetMainAlert = false
                    }
                } label: {
                    Text("취소")
                        .typography(.suit17SB)
                        .foregroundStyle(.black100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.black10)

                Button {
                    handleSetMainConfirm()
                } label: {
                    Text("확인")
                        .typography(.suit17SB)
                        .foregroundStyle(.white100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.main500)
            }
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 34))
        .padding(.horizontal, 51)
    }
}

// MARK: - 대표 설정 처리
extension BundleCompleteView {
    private func handleSetMainButtonTap() {
        guard let bundle = bundleVM.selectedBundle else { return }

        if bundle.isMain {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showAlreadyMainToast = true
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showSetMainAlert = true
            }
        }
    }

    private func handleSetMainConfirm() {
        guard NetworkManager.shared.isConnected else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showSetMainAlert = false
            }
            ToastManager.shared.show()
            return
        }

        guard let bundle = bundleVM.selectedBundle else { return }

        bundleVM.updateBundleMainStatus(bundle: bundle, isMain: true) { success in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showSetMainAlert = false
            }

            if success {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMainChanged = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        BundleCompleteView(
            router: NavigationRouter<WorkshopRoute>(),
            collectionVM: CollectionViewModel(),
            bundleVM: BundleViewModel()
        )
    }
}
