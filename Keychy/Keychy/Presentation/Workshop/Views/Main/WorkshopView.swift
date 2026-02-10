//
//  WorkshopView.swift
//  Keychy
//
//  Created by rundo on 10/16/25.
//

import SwiftUI
import NukeUI

// MARK: - Layout Constants

enum WorkshopLayout {
    static let topPadding: CGFloat = 60
    static let recentTemplateTopSpacing: CGFloat = 116
    static let bundleBannerTopSpacing: CGFloat = 20
    static let mainContentTopSpacing: CGFloat = 43
    static let stickyHeaderMinOffset: CGFloat = 120
    static let stickyHeaderMaxOffset: CGFloat = 730
    static let stickyHeaderOffsetAdjust: CGFloat = 20
    static let titleBarOpacityThreshold: CGFloat = 80
    static let titleBarOpacityRange: CGFloat = 70
}

// MARK: - Main View

struct WorkshopView: View {

    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Environment(UserManager.self) var userManager
    @State var viewModel: WorkshopViewModel
    @State private var hasInitialized = false

    // 만들기 메뉴 상태
    @State var showMakeMenu: Bool = false
    @State var makeMenuPosition: CGRect = .zero

    // 템플릿 선택 시트 상태
    @State private var showTemplateSelectSheet = false

    /// WorkshopTab에서 생성된 viewModel을 받아서 사용
    init(
        router: NavigationRouter<WorkshopRoute>,
        viewModel: WorkshopViewModel
    ) {
        self.router = router
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if viewModel.hasNetworkError {
                networkErrorView
            } else {
                ZStack(alignment: .top) {
                    // 메인 스크롤 콘텐츠
                    mainScrollContent

                    // 스크롤 시 나타나는 상단 타이틀 바
                    topTitleBar

                    // 스티키 헤더 (카테고리 탭 + 필터)
                    stickyHeaderSection
                }
                .background {
                    Image(viewModel.workshopToggle ? .workshopKeyringBGB : .workshopBundleBGB)
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $viewModel.showFilterSheet) {
            sortSheet
        }
        .overlay {
            if showMakeMenu {
                // 배경 탭으로 메뉴 닫기
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMakeMenu = false
                        }
                    }

                // 만들기 메뉴
                WorkshopMakeMenu(
                    position: makeMenuPosition,
                    onKeyring: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMakeMenu = false
                        }
                        showTemplateSelectSheet = true
                    },
                    onBundle: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMakeMenu = false
                        }
                        router.push(.bundleCreateView)
                    }
                )
            }
        }
        .task {
            guard !hasInitialized else { return }

            viewModel = WorkshopViewModel(userManager: userManager)
            hasInitialized = true

            await viewModel.initialize()
        }
        .onChange(of: viewModel.selectedCategory) { oldValue, newValue in
            viewModel.resetFilters()

            // 카테고리 전환 시 해당 카테고리가 로드되지 않았다면 로드
            Task {
                await viewModel.fetchDataForCategory(newValue)
            }
        }
        .withToast(position: .tabbar)
        .sheet(isPresented: $showTemplateSelectSheet) {
            WorkshopTemplateSelectSheet(
                isPresented: $showTemplateSelectSheet,
                router: router,
                templates: viewModel.templates
            )
        }
    }

    // MARK: - Main Content
    /// 메인 스크롤 콘텐츠
    var mainScrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 상단 배너 (코인 버튼 + 타이틀)
                topBannerSection

                Spacer()
                    .frame(height: viewModel.workshopToggle ?
                           WorkshopLayout.recentTemplateTopSpacing : WorkshopLayout.bundleBannerTopSpacing)

                // 키링 탭: 최근 사용 템플릿 / 번들 탭: 배너
                if viewModel.workshopToggle {
                    recentTemplateSection
                } else {
                    WorkshopBundleBanner()
                }

                Spacer()
                    .frame(height: WorkshopLayout.mainContentTopSpacing)

                // 메인 콘텐츠 (그리드)
                mainContentSection
                    .background(
                        GeometryReader { geo in
                            let minY = geo.frame(in: .global).minY
                            Color.clear
                                .onAppear {
                                    viewModel.mainContentOffset = minY
                                }
                                .onChange(of: minY) { oldValue, newValue in
                                    viewModel.mainContentOffset = newValue
                                }
                        }
                    )
            }
            .padding(.top, WorkshopLayout.topPadding)
            .background(alignment: .top) {
                Image(viewModel.workshopToggle ? .workshopKeyringBGF : .workshopBundleBGF)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

