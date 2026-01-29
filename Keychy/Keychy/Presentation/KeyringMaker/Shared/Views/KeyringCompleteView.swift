//
//  KeyringCompleteView.swift
//  KeytschPrototype
//
//  키링 완성 화면
//  - 모든 템플릿에서 공통으로 사용 가능
//

import SwiftUI
import SpriteKit
import FirebaseFirestore

struct KeyringCompleteView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: VM
    let navigationTitle: String
    
    var userManager: UserManager = UserManager.shared
    var reviewManager: ReviewManager = ReviewManager.shared
    
    // Festival에서 왔을 때 처리용 옵셔널 콜백
    var onCloseFromFestival: ((NavigationRouter<WorkshopRoute>) -> Void)?
    
    // 이미지 저장
    @State var showImageSaved = false
    @State var isCapturingImage = false
    
    // 영상 생성
    @State var isGeneratingVideo = false
    @State var showVideoSaved = false
    
    // 씬 인터랙션
    @State var isInteractionEnabled = false

    // 선물 포장
    @State var showPackageAlert = false
    @State var showPackingAlert = false

    // 비디오 생성기
    let videoGenerator = KeyringVideoGenerator()
    
    var body: some View {
        ZStack {
            // 1. 배경
            backgroundView
            
            // 2. 메인 컨텐츠
            mainContent
            
            // 3. Alerts 오버레이
            alertsOverlay
            
            // 4. 로딩 오버레이
            loadingOverlay
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            closeToolbarItem
            titleToolbarItem
            collectionToolbarItem
        }
        .onAppear {
            checkReviewTriggers()
        }
        .withToast(position: .default)
    }
}

// MARK: - View Components
extension KeyringCompleteView {
    /// 배경 이미지
    private var backgroundView: some View {
        Image(.completeBG2)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .cinematicAppear(delay: 0, duration: 0.6, style: .fadeIn)
            .blur(radius: isAlertShowing ? 15 : 0)
    }
    
    /// 메인 컨텐츠 (키링씬 + 정보 + 버튼)
    private var mainContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 키링 씬 (화면 높이의 55%)
                keyringScene
                    .frame(height: geometry.size.height * 0.53)
                    .cinematicAppear(delay: 0.2, duration: 0.8, style: .full)
                    .offset(x: 0, y: -20)
                
                // 키링 정보
                keyringInfo
                    .cinematicAppear(delay: 0.6, duration: 0.8, style: .slideUp)
                    .padding(.bottom, 30)
                
                // 액션 버튼
                actionButtons
                    .cinematicAppear(delay: 1.0, duration: 0.8, style: .fadeIn)
                    .opacity(isCapturingImage ? 0 : 1)
            }
            .adaptiveTopPaddingAlt()
        }
        .blur(radius: isAlertShowing ? 15 : 0)
    }
    
    /// Alerts 오버레이
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

        // 선물 포장 확인 팝업
        if showPackageAlert {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)

            PackagePopup(
                onCancel: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPackageAlert = false
                    }
                },
                onConfirm: {
                    handlePackageConfirm()
                }
            )
            .zIndex(100)
        }

        // 포장 중 로딩
        if showPackingAlert {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)

            LoadingAlert(
                type: .longWithPresent,
                message: "선물 포장 중.."
            )
            .zIndex(101)
        }
    }
    
    /// 로딩 오버레이
    @ViewBuilder
    private var loadingOverlay: some View {
        if isGeneratingVideo {
            Color.black20
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("영상 생성 중...")
                    .typography(.suit17SB)
                    .foregroundColor(.white)
                
                Text("5~10초 소요")
                    .typography(.suit14M)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}

// MARK: - KeyringScene Section
extension KeyringCompleteView {
    private var keyringScene: some View {
        KeyringSceneView(
            viewModel: viewModel,
            backgroundColor: .clear,
            applyWelcomeImpulse: true,
            onSceneReady: {
                // Setup 완료 후 impulse 적용 시간(0.5초) + 여유 시간 대기 후 터치 활성화
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isInteractionEnabled = true
                }
            }
        )
        .frame(maxWidth: .infinity)
        .allowsHitTesting(isInteractionEnabled)
    }
}

// MARK: - Toolbar Items
extension KeyringCompleteView {
    /// Alert 표시 중 여부
    private var isAlertShowing: Bool {
        showImageSaved || showVideoSaved || isGeneratingVideo || showPackageAlert || showPackingAlert
    }
    
    var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                viewModel.resetAll()
                
                // Festival에서 온 경우 콜백 실행
                if let onCloseFromFestival = onCloseFromFestival {
                    onCloseFromFestival(router)
                } else {
                    // 일반적인 경우 router reset
                    TabBarManager.show()
                    router.reset()
                }
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
            Text("키링 완성!")
                .typography(.notosans17M)
                .foregroundStyle(.black100)
                .opacity(isAlertShowing ? 0 : 1)
        }
    }
    
    var collectionToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                navigateToCollection()
            } label: {
                Image(.goToCollection)
            }
            .opacity(isAlertShowing ? 0 : 1)
            .allowsHitTesting(!isAlertShowing)
        }
        .sharedBackgroundVisibility(isAlertShowing ? .hidden : .visible)
    }

    /// 콜렉션으로 이동 (부드러운 전환)
    private func navigateToCollection() {
        // 1. 탭 전환 먼저 (현재 뷰가 보이는 상태에서)
        TabBarManager.switchTo(.collection)
        TabBarManager.show()

        // 2. 백그라운드에서 Workshop 스택 정리
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.resetAll()
            router.reset()
        }
    }
}

// MARK: - 키링 정보 뷰
extension KeyringCompleteView {
    private var keyringInfo: some View {
        VStack(spacing: 0) {
            Text(viewModel.nameText)
                .typography(getBottomPadding(0) == 0 ? .malang24B : .malang26B)
                .foregroundStyle(.black100)
                .padding(.bottom, 2)
            
            Text(formattedDate(date: viewModel.createdAt))
                .typography(.suit14M)
                .foregroundStyle(.black100)
                .padding(.bottom, 10)
            
            if let nickname = userManager.currentUser?.nickname {
                Text("@\(nickname)")
                    .typography(getBottomPadding(0) == 0 ? .notosans12R : .notosans14R)
                    .foregroundStyle(.gray500)
                    .padding(.vertical, 1)
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

// MARK: - 버튼
extension KeyringCompleteView {
    /// 버튼 사이즈 (디바이스별)
    private var buttonSize: CGFloat {
        getBottomPadding(0) == 0 ? 55 : 65
    }
    
    /// 액션 버튼 컴포넌트
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
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 24))
    }
    
    /// 하단 액션 버튼 영역
    private var actionButtons: some View {
        HStack(spacing: 17) {
            // 이미지 저장
            actionButton(image: .save, title: "이미지 저장") {
                captureAndSaveImage()
            }
            
            // 공유
            actionButton(image: .share, title: "공유") {
                // TODO: 공유 기능
            }
            
            // 선물하기
            actionButton(image: .present, title: "선물하기") {
                // 이미 포장된 경우 바로 이동
                if let keyringDocumentId = viewModel.savedKeyringDocumentId,
                   let postOfficeId = viewModel.packagedPostOfficeId,
                   let shareLink = viewModel.packagedShareLink {
                    router.push(.packageComplete(
                        keyringDocumentId: keyringDocumentId,
                        postOfficeId: postOfficeId,
                        templateId: viewModel.templateId,
                        shareLink: shareLink
                    ))
                    return
                }

                // 네트워크 체크
                guard NetworkManager.shared.isConnected else {
                    ToastManager.shared.show()
                    return
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showPackageAlert = true
                }
            }
        }
    }
}

// MARK: - 선물 포장 처리
extension KeyringCompleteView {
    /// 선물 포장 확인 처리
    private func handlePackageConfirm() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showPackageAlert = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard let keyringDocumentId = viewModel.savedKeyringDocumentId else {
                print("[Package] keyringDocumentId 없음")
                return
            }

            // 이미 포장된 경우 바로 이동
            if let postOfficeId = viewModel.packagedPostOfficeId,
               let shareLink = viewModel.packagedShareLink {
                print("[Package] 이미 포장됨 - 바로 이동")
                router.push(.packageComplete(
                    keyringDocumentId: keyringDocumentId,
                    postOfficeId: postOfficeId,
                    templateId: viewModel.templateId,
                    shareLink: shareLink
                ))
                return
            }

            // 새로 포장하는 경우
            guard let uid = userManager.currentUser?.id else {
                print("[Package] uid 없음")
                return
            }

            // 포장 중 로딩 표시
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showPackingAlert = true
            }

            // 최소 로딩 시간 보장을 위한 시작 시간 기록
            let startTime = Date()
            let minimumLoadingDuration: TimeInterval = 1.0

            // 패키징 실행
            KeyringPackageManager.packageKeyring(
                uid: uid,
                keyringDocumentId: keyringDocumentId
            ) { success, postOfficeId, shareLink in
                let elapsed = Date().timeIntervalSince(startTime)
                let remainingDelay = max(0, minimumLoadingDuration - elapsed)

                // 최소 1초 로딩 후 처리
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingDelay) {
                    showPackingAlert = false

                    if success, let postOfficeId = postOfficeId, let shareLink = shareLink {
                        // 포장 정보 저장 (뒤로갔다 다시 올 때 사용)
                        viewModel.packagedPostOfficeId = postOfficeId
                        viewModel.packagedShareLink = shareLink

                        // 성공 - 포장 완료 화면으로 이동
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            router.push(.packageComplete(
                                keyringDocumentId: keyringDocumentId,
                                postOfficeId: postOfficeId,
                                templateId: viewModel.templateId,
                                shareLink: shareLink
                            ))
                        }
                    } else {
                        print("[Package] 포장 실패")
                        ToastManager.shared.show()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        KeyringCompleteView(
            router: NavigationRouter<WorkshopRoute>(),
            viewModel: PolaroidVM(),
            navigationTitle: "키링 완성"
        )
    }
}
