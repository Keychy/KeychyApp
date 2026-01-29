//
//  KeyringPackageCompleteView.swift
//  Keychy
//
//  키링 선물 포장 완료 화면 (Workshop용)
//

import SwiftUI
import FirebaseFirestore

struct KeyringPackageCompleteView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    var viewModel: any KeyringViewModelProtocol

    let keyringDocumentId: String
    let postOfficeId: String
    let shareLink: String  // 패키징 시 생성된 링크 직접 전달

    @State private var keyring: Keyring?
    @State private var authorName: String = ""
    @State private var isLoading: Bool = true
    @State private var showLinkCopied: Bool = false
    @State private var showImageSaved: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let keyring = keyring {
                    packagedView(keyring: keyring)
                        .blur(radius: shouldApplyBlur ? 10 : 0)
                        .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
                }

                // 로딩 오버레이
                if isLoading {
                    Color.black20
                        .ignoresSafeArea()

                    LoadingAlert(type: .short40, message: nil)
                        .zIndex(101)
                }

                // 이미지 저장 Alert
                if showImageSaved {
                    Color.black20
                        .ignoresSafeArea()
                        .zIndex(99)

                    KeychyAlert(
                        type: .imageSave,
                        message: "이미지가 저장되었어요!",
                        isPresented: $showImageSaved
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .zIndex(101)
                }

                // 링크 복사 Alert
                if showLinkCopied {
                    Color.black20
                        .ignoresSafeArea()
                        .zIndex(99)

                    KeychyAlert(
                        type: .linkCopy,
                        message: "링크가 복사되었어요!",
                        isPresented: $showLinkCopied
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .zIndex(101)
                }

                // 네비게이션 바
                customNavigationBar
                    .blur(radius: shouldApplyBlur ? 15 : 0)
                    .adaptiveTopPadding()
                    .zIndex(0)
            }
            .padding(.top, 1)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            TabBarManager.hide()
            loadKeyringData()
        }
    }

    private var shouldApplyBlur: Bool {
        isLoading || showLinkCopied || showImageSaved
    }
}

// MARK: - Views
extension KeyringPackageCompleteView {
    private func packagedView(keyring: Keyring) -> some View {
        GeometryReader { geometry in
            let heightRatio = geometry.size.height / 852
            let isSmallScreen = geometry.size.height < 700

            ZStack {
                // 배경
                Image(.greenBackground)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .adaptiveTopPadding()

                    // 헤더 텍스트
                    VStack(spacing: 15) {
                        Text("키링 포장이 완료되었어요!")
                            .typography(.suit20B)
                            .foregroundColor(.black100)
                            .padding(.top, 10)

                        Text("링크나 QR로 바로 공유할 수 있어요")
                            .font(.suit16M)
                            .foregroundColor(.black100)
                    }
                    .padding(.top, isSmallScreen ? -70 : 78)

                    Spacer()
                        .frame(height: isSmallScreen ? 24 : 48)

                    // 포장된 키링 뷰 (기존 컴포넌트 재사용)
                    PackagedKeyringView(
                        keyring: keyring,
                        postOfficeId: postOfficeId,
                        shareLink: shareLink,
                        authorName: authorName,
                        isLoading: $isLoading,
                        onImageSaved: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showImageSaved = true
                            }
                        },
                        onLinkCopied: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showLinkCopied = true
                            }
                        }
                    )
                    .frame(height: isSmallScreen ? 500 : 600)
                    .scaleEffect(heightRatio)

                    Spacer()
                        .adaptiveBottomPadding()
                }
            }
        }
    }

    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading - 뒤로가기 버튼 (키링 완성뷰로)
            Button {
                router.pop()
            } label: {
                Image(.backIcon)
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        } center: {
            Spacer()
        } trailing: {
            // Trailing - 홈 버튼
            Button {
                navigateToHome()
            } label: {
                Image(.homeBlack)
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    /// 홈 탭으로 이동
    private func navigateToHome() {
        TabBarManager.switchTo(.home)
        TabBarManager.show()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.resetAll()
            router.reset()
        }
    }
}

// MARK: - Data Loading
extension KeyringPackageCompleteView {
    private func loadKeyringData() {
        let db = Firestore.firestore()

        print("[PackageComplete] 키링 로드 시작 - ID: \(keyringDocumentId)")

        db.collection("Keyring")
            .document(keyringDocumentId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("[PackageComplete] 키링 로드 실패: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                guard let data = snapshot?.data() else {
                    print("[PackageComplete] 키링 데이터 없음 - documentId: \(keyringDocumentId)")
                    isLoading = false
                    return
                }

                print("[PackageComplete] 키링 데이터 수신: \(data.keys)")

                // Keyring 파싱
                if let keyring = Keyring(documentId: keyringDocumentId, data: data) {
                    print("[PackageComplete] 키링 파싱 성공: \(keyring.name)")
                    self.keyring = keyring
                    loadAuthorName(authorId: keyring.authorId)
                } else {
                    print("[PackageComplete] 키링 파싱 실패 - 필수 필드 누락")
                    isLoading = false
                }
            }
    }

    private func loadAuthorName(authorId: String) {
        let db = Firestore.firestore()

        db.collection("User")
            .document(authorId)
            .getDocument { snapshot, error in
                if let data = snapshot?.data(),
                   let name = data["nickname"] as? String {
                    self.authorName = name
                } else {
                    self.authorName = "알 수 없음"
                }
            }
    }

}
