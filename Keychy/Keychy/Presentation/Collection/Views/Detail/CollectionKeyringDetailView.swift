//
//  CollectionKeyringDetailView.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import SpriteKit
import FirebaseFirestore
import Photos

struct CollectionKeyringDetailView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @Bindable var viewModel: CollectionViewModel
    
    @State var sheetDetent: PresentationDetent = .fraction(0.48)
    @State private var scene: KeyringDetailScene?
    @State private var isLoading: Bool = true
    @State var isSheetPresented: Bool = false
    @State var isNavigatingDeeper: Bool = false
    @State var authorName: String = ""
    @State var senderName: String = ""
    @State var copyVoucher: Int = 0
    @State var showMenu: Bool = false
    @State var showDeleteAlert: Bool = false
    @State var showDeleteCompleteAlert: Bool = false
    @State var showCopyAlert: Bool = false
    @State var showCopyCompleteAlert: Bool = false
    @State var showCopyLackAlert: Bool = false
    @State var showCopyingAlert: Bool = false
    @State var showInvenFullAlert: Bool = false
    @State var showPackageAlert: Bool = false
    @State var showPackingAlert: Bool = false
    @State var menuPosition: CGRect = .zero

    // 이미지 저장 관련
    @State var showImageSaved: Bool = false
    @State var checkmarkScale: CGFloat = 0.0
    @State var checkmarkOpacity: Double = 0.0
    @State var showUIForCapture: Bool = true  // 캡처 시 UI 표시 여부

    // 영상 생성 및 공유
    @State var isGeneratingVideo: Bool = false
    @State var showVideoSaved: Bool = false
    @State var videoGenerator = KeyringVideoGenerator()
    @State var cachedVideoURL: URL?
    @State var showShareSheet: Bool = false
    @State var pendingShareAction: Bool = false  // 시트 닫힌 후 공유 실행 대기

    // 위젯 추가/제거 관련
    @State var showWidgetAddedToast: Bool = false
    @State var showWidgetRemoveAlert: Bool = false
    @State var showWidgetRemovedToast: Bool = false
    @State var isGeneratingAnimationFrames: Bool = false

    // 포장 관련
    @State var postOfficeId: String = ""

    let isSearchMode: Bool  // 검색모드 여부
    
    // 키링 정보
    @State var keyring: Keyring
    
    // 초기화 시 keyring을 받아서 State에 저장
    init(
        router: NavigationRouter<CollectionRoute>,
        viewModel: CollectionViewModel,
        keyring: Keyring,
        isSearchMode: Bool = false
    ) {
        self.router = router
        self.viewModel = viewModel
        self._keyring = State(initialValue: keyring)
        self.isSearchMode = isSearchMode
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Image(.whiteBackground)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: shouldApplyBlur ? 10 : 0)
                    .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
                
                VStack(spacing: 0) {
                    Spacer()

                    ZStack(alignment: .center) {
                        keyringScene
                            .frame(height: geometry.size.height * 0.8)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.4)
                            .blur(radius: shouldApplyBlur ? 10 : 0)
                            .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)

                        bottomSection
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.942)
                            .opacity(showUIForCapture ? 1 : 0)
                            .blur(radius: shouldApplyBlur ? 15 : 0)
                    }
                }

                if showMenu {
                    menuOverlay
                }
                
                if isLoading {
                    Color.black20
                        .ignoresSafeArea()
                        
                    LoadingAlert(type: .short40, message: nil)
                        .zIndex(200)
                }
                
                alertOverlays
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                    .zIndex(200)
                
                customNavigationBar
                    .blur(radius: shouldApplyBlur ? 15 : 0)
                    .adaptiveTopPadding()
                    .opacity(showUIForCapture ? 1 : 0)
                    .zIndex(0)
            }
            
        }
        .swipeBackGesture(enabled: false)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(false)
        .withToast(position: .default)
        .sheet(isPresented: $isSheetPresented, onDismiss: {
            // 시트 완전히 닫힌 후 대기 중인 공유 액션 실행
            if pendingShareAction {
                pendingShareAction = false
                if cachedVideoURL != nil {
                    showShareSheet = true
                } else {
                    Task {
                        await generateVideoForShare()
                    }
                }
            }
        }) {
            infoSheet
                .presentationDetents([.fraction(0.48), .fraction(0.93)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.48)))
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = cachedVideoURL {
                ShareSheet(items: [url])
                    .presentationDetents([.fraction(0.65)])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            handleViewAppear()
            refreshCopyVoucher()
        }
        .onDisappear {
            handleViewDisappear()
            cleanupCachedVideo()
        }
        .onPreferenceChange(MenuButtonPreferenceKey.self) { frame in
            menuPosition = frame
        }
        .task {
            // 뷰가 다시 나타날 때 키링 데이터 새로고침
            await refreshKeyringData()
        }
    }
    
    private var shouldApplyBlur: Bool {
        isLoading ||
        showCopyCompleteAlert ||
        showCopyingAlert ||
        showPackingAlert ||
        showImageSaved ||
        isGeneratingVideo ||
        showVideoSaved ||
        false
    }
    
    // 복사권 개수 리프레쉬
    func refreshCopyVoucher() {
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else { return }
        
        viewModel.fetchUserCollectionData(uid: uid) { success in
            if success {
                print("복사권 새로고침: \(viewModel.copyVoucher)개")
            }
        }
    }
    
    /// 키링 데이터 새로고침 (편집 후 돌아왔을 때)
    private func refreshKeyringData() async {
        guard let documentId = keyring.documentId else { return }
        
        // ViewModel에서 최신 키링 데이터 찾기
        if let updatedKeyring = viewModel.keyring.first(where: { $0.documentId == documentId }) {
            await MainActor.run {
                self.keyring = updatedKeyring
            }
        } else {
            // 로컬에 없으면 Firebase에서 직접 가져오기
            await withCheckedContinuation { continuation in
                viewModel.fetchKeyringById(keyringId: documentId) { fetchedKeyring in
                    if let fetchedKeyring = fetchedKeyring {
                        Task { @MainActor in
                            self.keyring = fetchedKeyring
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    /// 씬 스케일 (시트 최대화 시 작게, 최소화 시 크게)
    private var sceneScale: CGFloat {
        isSheetPresented == false ? 1.1 : 0.8
    }
    
    /// 씬 Y 오프셋 (시트 최대화 시 위로 이동)
    private var sceneYOffset: CGFloat {
        isSheetPresented == false ? 30 : -50
    }
}

// MARK: - 툴바
extension CollectionKeyringDetailView {
    private var safeAreaTop: CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return 0
        }
        return window.safeAreaInsets.top
    }

    var customNavigationBar: some View {
        ZStack {
            // 타이틀 (화면 정중앙)
            Text(showUIForCapture ? keyring.name : "")
                .typography(.notosans17M)
                .foregroundStyle(.gray600)

            // Leading & Trailing
            HStack {
                // 뒤로가기 버튼
                BackToolbarButton {
                    isSheetPresented = false
                    router.pop()
                }
                .opacity(showUIForCapture ? 1 : 0)

                Spacer()

                // 오른쪽 버튼들
                HStack(spacing: 10) {
                    // 이미지 저장 버튼
                    Button {
                        captureAndSaveImage()
                    } label: {
                        Image(.imageDownload)
                    }
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)

                    // 메뉴 버튼
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu.toggle()
                        }
                    }) {
                        Image(.menuIcon)
                            .resizable()
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: MenuButtonPreferenceKey.self,
                                        value: geometry.frame(in: .global)
                                    )
                                }
                            )
                    }
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
                }
                .opacity(showUIForCapture ? 1 : 0)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
        .padding(.top, safeAreaTop)
    }
}

// MARK: - 키링 씬
extension CollectionKeyringDetailView {
    var keyringScene: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 30)
                
                KeyringDetailSceneView(
                    keyring: keyring,
                    isLoading: $isLoading
                )
                
                Spacer()
            }
            .scaleEffect(sceneScale)
            .offset(y: sceneYOffset)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isSheetPresented)
            .allowsHitTesting(isSheetPresented == false)
        }
    }

}

// MARK: - 하단 영역
extension CollectionKeyringDetailView {
    // 하단 버튼 섹션 - 포장, 정보 보기, 이미지 저장
    private var bottomSection: some View {
        HStack {
            packageButton

            Spacer()

            Button {
                // 정보 시트 열기
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    isSheetPresented = true
                    sheetDetent = .fraction(0.48)
                }
            } label: {
                Text("정보 보기")
                    .typography(.suit16M)
                    .foregroundStyle(.white100)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.main500)
            )
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))

            Spacer()

            shareButton
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 36, trailing: 16))
        .adaptiveBottomPadding()
        .opacity(isSheetPresented ? 0 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSheetPresented)
    }

    private var shareButton: some View {
        Button(action: {
            if cachedVideoURL != nil {
                showShareSheet = true
                return
            }
            Task {
                await generateVideoForShare()
            }
        }) {
            Image(.share)
        }
        .disabled(isGeneratingVideo)
        .frame(width: 48, height: 48)
        .glassEffect(.regular.interactive(), in: .circle)
        .opacity(isGeneratingVideo ? 0.5 : 1)
    }

    private var packageButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showPackageAlert = true
            }
        }) {
            Image(.presentIcon)
        }
        .frame(width: 48, height: 48)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}
