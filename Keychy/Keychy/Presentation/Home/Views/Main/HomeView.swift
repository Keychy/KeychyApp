//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//
// 홈 화면 - 메인 뭉치의 키링들을 3D 씬으로 표시

import SwiftUI
import NukeUI
import FirebaseFirestore

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>

    @Bindable var userManager: UserManager

    @State var collectionViewModel: CollectionViewModel
    @State var bundleViewModel: BundleViewModel

    /// 탭 선택 상태 (탭 전환 감지용)
    @Binding var selectedTab: Int

    /// 배경 로드 완료 콜백
    var onBackgroundLoaded: (() -> Void)? = nil

    /// GlassEffect 애니메이션을 위한 네임스페이스
    @Namespace private var unionNamespace

    @State private var viewModel = HomeViewModel()
    @State private var isTabBarVisible = true

    /// 뭉치 변경 팝업 표시 여부
    @State private var showBundleSwitchPopup = false

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // 조건부: 네트워크 에러 화면 또는 정상 콘텐츠
            if viewModel.hasNetworkError {
                networkErrorView
                navigationButtons
            } else {
                // 블러 영역
                ZStack(alignment: .top) {
                    if let bundle = bundleViewModel.selectedBundle,
                       let carabiner = bundleViewModel.resolveCarabiner(from: bundle.selectedCarabiner),
                       let background = bundleViewModel.selectedBackground {
                        MultiKeyringSceneView(
                            keyringDataList: viewModel.keyringDataList,
                            ringType: .basic,
                            chainType: .basic,
                            backgroundColor: .clear,
                            backgroundImageURL: background.backgroundImage,
                            carabinerBackImageURL: carabiner.backImageURL,
                            carabinerFrontImageURL: carabiner.frontImageURL,
                            carabinerX: carabiner.carabinerX,
                            carabinerY: carabiner.carabinerY,
                            carabinerWidth: carabiner.carabinerWidth,
                            currentCarabinerType: carabiner.type,
                            onBackgroundLoaded: onBackgroundLoaded,
                            onAllKeyringsReady: {
                                viewModel.handleAllKeyringsReady()
                            }
                        )
                        .ignoresSafeArea()
                        /// 씬 재생성 조건을 위한 ID 설정
                        /// 뭉치, 배경, 카라비너, 키링 구성이 변경되면 씬을 완전히 재생성
                        .id("\(bundle.documentId ?? "")_\(background.id ?? "")_\(carabiner.id ?? "")_\(viewModel.keyringDataList.map(\.bodyImageURL).joined(separator: ","))")
                    } else {
                        // 데이터 로딩 중
                        Color.clear.ignoresSafeArea()
                    }

                    // 네비게이션 버튼 (블러 적용됨)
                    navigationButtons
                }
                .blur(radius: viewModel.isSceneReady ? 0 : 15)

                // 로딩 알림 (씬 준비 전까지 표시)
                if !viewModel.isSceneReady {
                    LoadingAlert(type: .longWithKeychy, message: "키링 뭉치를 불러오고 있어요")
                }
            }

            // 뭉치 변경 팝업 오버레이
            if showBundleSwitchPopup {
                bundleSwitchPopupOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(isTabBarVisible ? .visible : .hidden, for: .tabBar)
        .onAppear {
            // 알림 리스너 시작
            userManager.startNotificationListener()
        }
        .task {
            // 네트워크 체크
            guard NetworkManager.shared.isConnected else {
                viewModel.hasNetworkError = true
                return
            }

            // 최초 뷰가 나타날 때 메인 뭉치 데이터 로드 (우선순위)
            await viewModel.loadMainBundle(collectionViewModel: collectionViewModel, bundleViewModel: bundleViewModel, onBackgroundLoaded: onBackgroundLoaded)
        }
        .onChange(of: viewModel.keyringDataList) { _, _ in
            // 키링 데이터가 변경되면 씬 준비 상태 초기화 (씬이 자동으로 재생성됨)
            viewModel.handleKeyringDataChange()
        }
        .onChange(of: NetworkManager.shared.isConnected) { oldValue, newValue in
              // 네트워크가 복구되고, 에러 상태였다면 자동 재시도
              if !oldValue && newValue && viewModel.hasNetworkError {
                  Task {
                      await viewModel.retryLoadMainBundle(
                        collectionViewModel: collectionViewModel, bundleViewModel: bundleViewModel,
                          onBackgroundLoaded: onBackgroundLoaded
                      )
                  }
              }
          }
        .onChange(of: selectedTab) { _, _ in
            // 탭 전환 시 뭉치 변경 팝업 닫기
            if showBundleSwitchPopup {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showBundleSwitchPopup = false
                }
            }
        }
        .withToast(position: .tabbar)
    }
}

// MARK: - View Components
extension HomeView {
    /// 네트워크 에러 화면
    private var networkErrorView: some View {
        NoInternetView(topPadding: getSafeAreaTop() + 10, onRetry: {
            Task {
                await viewModel.retryLoadMainBundle(
                    collectionViewModel: collectionViewModel, bundleViewModel: bundleViewModel,
                    onBackgroundLoaded: onBackgroundLoaded
                )
            }
        })
        .ignoresSafeArea()
    }

    /// 상단 네비게이션 버튼들
    private var navigationButtons: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack(spacing: 10) {
                // 뭉치 변경 버튼 (좌측) - 뭉치가 2개 이상일 때만 표시
                bundleSwitchButton

                Spacer()

                // 알림 및 마이페이지 버튼 그룹
                GlassEffectContainer {
                    HStack {
                        Button {
                            router.push(.alarmView)
                        } label: {
                            Image(userManager.hasUnreadNotifications ? "alarmSent" : "alarm")
                        }
                        .frame(width: 44, height: 44)
                        .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                        .buttonStyle(.glass)

                        Button {
                            router.push(.myPageView)
                        } label: {
                            Image(.myPageIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)

                        }
                        .frame(width: 44, height: 44)
                        .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                        .buttonStyle(.glass)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    /// 뭉치 변경 버튼
    @ViewBuilder
    private var bundleSwitchButton: some View {
        let hasMutipleBundles = bundleViewModel.bundles.count >= 2
        let bundleName = bundleViewModel.selectedBundle?.name ?? "뭉치"

        BundleSwitchButton(
            bundleName: bundleName,
            isExpanded: showBundleSwitchPopup,
            isEnabled: hasMutipleBundles,
            onTap: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showBundleSwitchPopup.toggle()
                }
            }
        )
    }

    /// 뭉치 변경 팝업 오버레이
    private var bundleSwitchPopupOverlay: some View {
        ZStack(alignment: .topLeading) {
            // 배경 탭하면 닫기
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showBundleSwitchPopup = false
                    }
                }

            // 팝업 (버튼 아래에 위치)
            BundleSwitchPopup(
                bundles: bundleViewModel.sortedBundles,
                currentBundle: bundleViewModel.selectedBundle,
                onSelect: { selectedBundle in
                    handleBundleSelection(selectedBundle)
                }
            )
            .padding(.top, getSafeAreaTop() + 50)
            .padding(.leading, 20)
            .transition(.scale(scale: 0.9, anchor: .topLeading).combined(with: .opacity))
        }
        .ignoresSafeArea()
    }

    /// 뭉치 선택 처리
    private func handleBundleSelection(_ bundle: KeyringBundle) {
        // 같은 뭉치 선택 시 팝업만 닫기
        guard bundle.documentId != bundleViewModel.selectedBundle?.documentId else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showBundleSwitchPopup = false
            }
            return
        }

        // 팝업 닫기
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showBundleSwitchPopup = false
        }

        // 로딩 시작
        viewModel.isSceneReady = false

        // 선택된 뭉치로 변경 후 로드
        Task {
            await viewModel.switchBundle(
                to: bundle,
                collectionViewModel: collectionViewModel,
                bundleViewModel: bundleViewModel
            )
        }
    }
}

