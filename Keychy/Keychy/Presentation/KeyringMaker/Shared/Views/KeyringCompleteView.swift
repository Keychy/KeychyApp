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
        }
        .onAppear {
            checkReviewTriggers()
        }
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
                    .border(.red)
                    .offset(x: 0, y: -20)

                // 키링 정보
                keyringInfo
                    .cinematicAppear(delay: 0.6, duration: 0.8, style: .slideUp)
                    .padding(.bottom, 30)

                // 저장 버튼
                saveButton
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
        showImageSaved || showVideoSaved || isGeneratingVideo
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
                .typography(.suit17B)
                .foregroundStyle(.black100)
                .opacity(isAlertShowing ? 0 : 1)
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
                    .foregroundStyle(.black100)
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

// MARK: - 저장 버튼
extension KeyringCompleteView {
    private var saveButton: some View {
        HStack(spacing: 20) {
            // 이미지 저장 버튼
            VStack(spacing: 9) {
                Button(action: {
                    captureAndSaveImage()
                }) {
                    Image(.imageDownload)
                }
                .frame(
                    width: getBottomPadding(0) == 0 ? 55 : 65,
                    height: getBottomPadding(0) == 0 ? 55 : 65
                )
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)

                Text("이미지 저장")
                    .typography(.suit13SB)
                    .foregroundStyle(.black100)
            }

            // 영상 생성 버튼
            VStack(spacing: 9) {
                Button(action: {
                    Task {
                        await generateAndSaveVideo()
                    }
                }) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black100)
                }
                .frame(
                    width: getBottomPadding(0) == 0 ? 55 : 65,
                    height: getBottomPadding(0) == 0 ? 55 : 65
                )
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .disabled(isGeneratingVideo)

                Text("영상 생성")
                    .typography(.suit13SB)
                    .foregroundStyle(.black100)
            }
            .opacity(isGeneratingVideo ? 0.5 : 1)
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
