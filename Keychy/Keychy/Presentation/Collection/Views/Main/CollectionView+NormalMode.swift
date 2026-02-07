//
//  CollectionView+NormalMode.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

// MARK: - Normal Mode View
extension CollectionView {
    /// 오버레이 헤더 높이 (headerSection + tagSection + collectionHeader)
    /// - headerSection: 60(top padding) + ~40(buttons) + 12(padding) ≈ 112pt
    /// - tagSection: 4(Spacing.xs) + 35(TabBar) ≈ 39pt
    /// - collectionHeader: ~35pt (sortButton + spacing)
    /// - 총합: ~195pt
    private var overlayHeaderHeight: CGFloat {
        collectionViewModel.collectionToggle ? 195 : 165
    }

    // MARK: - Normal Mode View
    var normalModeView: some View {
        Group {
            if collectionViewModel.hasNetworkError {
                // 네트워크 에러: 오버레이 형태
                networkErrorView
            } else {
                // 정상 상태: ZStack 오버레이 형태 (iOS 빌트인 탭 스크롤 지원)
                if collectionViewModel.collectionToggle {
                    keyringTabView
                } else {
                    bundleTabView
                }
            }
        }
    }
    
    private var networkErrorView: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()

            NoInternetView(topPadding: getSafeAreaTop() + 90, onRetry: {
                Task {
                    guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                        print("UID를 찾을 수 없습니다")
                        return
                    }
                    await collectionViewModel.retryFetchData(userId: uid)
                }
            })
            .ignoresSafeArea()

            VStack {
                VStack {
                    headerSection
                        .padding(.horizontal, Spacing.margin)
                        .padding(.top, 2)

                    if collectionViewModel.collectionToggle {
                        tagSection
                            .padding(.horizontal, Spacing.xs)
                    }
                }
                .background(Color.white)

                Spacer()
            }
        }
    }
    
    private var keyringTabView: some View {
        ZStack(alignment: .top) {
            // 전체 화면 ScrollView (pullToRefresh가 생성)
            normalCollectionSection

            // 고정 오버레이 헤더
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, Spacing.margin)
                    .padding(.top, 2)
                    .padding(.bottom, 10)

                tagSection
                    .padding(.horizontal, Spacing.xs)

                collectionHeader
                    .padding(.horizontal, Spacing.padding)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
            .background(Color.white)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if showSearchBar && !isSearching {
                isSearchFieldFocused = false

                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSearchBar = false
                }
            }
        }
    }
    
    private var bundleTabView: some View {
        ZStack(alignment: .top) {
            bundleGridSection

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, Spacing.margin)
                    .padding(.top, 2)
                    .padding(.bottom, 10)
                
                collectionHeader
                    .padding(.horizontal, Spacing.padding)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
            }
            .background(Color.white)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if showSearchBar && !isSearching {
                isSearchFieldFocused = false

                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSearchBar = false
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 0) {
            // 탭 토글 버튼
            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        collectionViewModel.collectionToggle = true
                    }
                } label: {
                    Text("키링")
                        .typography(.nanum24EB)
                        .foregroundColor(collectionViewModel.collectionToggle ? .black100 : .gray100)
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        collectionViewModel.collectionToggle = false
                    }
                } label: {
                    Text("뭉치")
                        .typography(.nanum24EB)
                        .foregroundColor(collectionViewModel.collectionToggle ? .gray100 : .black100)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // 디버그 버튼 (빌드앱일 때만 표시)
            #if DEBUG
            Button {
                showCachedImagesDebug = true
                KeyringImageCache.shared.printAllCachedFiles()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)

                    Image(systemName: "photo.stack")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
            .padding(.trailing, 10)
            #endif

            CircleGlassButton(imageName: "BundleIcon",
                              action: {
                isSearchFieldFocused = false
                showSearchBar = false
                
                router.push(.bundleInventoryView)
            }
            )
            .padding(.trailing, 10)
            
            CircleGlassButton(
                imageName: "Search",
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSearchBar = true
                    }
                    // 키보드 올리기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFieldFocused = true
                    }
                }
            )
        }
        .padding(.top, 60)
    }
    
    private var tagSection: some View {
        CategoryTabBarWithLongPress(
            categories: categories,
            selectedCategory: $selectedCategory,
            onLongPress: { category, position in
                // Long press 시 메뉴 표시
                showingMenuFor = category
                menuPosition = position
            },
            editableCategories: Set(collectionViewModel.tags) // 전체는 제외
        )
        .padding(.top, Spacing.xs)
        .padding(.horizontal, 2)
    }

    private var normalCollectionSection: some View {
        VStack(spacing: 0) {
            // 오버레이 헤더 높이만큼 상단 여백
            Spacer()
                .frame(height: overlayHeaderHeight)

            if filteredKeyrings.isEmpty {
                emptyView
            } else {
                collectionGridView(keyrings: filteredKeyrings)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.top, 20)
            }
        }
        .pullToRefresh(topPadding: overlayHeaderHeight) {
            try? await Task.sleep(for: .seconds(1))
            fetchUserData()
            retryFailedCaches()
        }
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                if showSearchBar {
                    isSearchFieldFocused = false

                    if !isSearching {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSearchBar = false
                        }
                    }
                }
            }
        )
    }
    
    // MARK: - 뭉치 그리드 섹션
    private var bundleGridSection: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: overlayHeaderHeight)

            if bundleViewModel.sortedBundles.isEmpty {
                bundleEmptyView
            } else {
                bundleGrid
                    .padding(.horizontal, Spacing.xs)
                    .padding(.top, 20)
            }
        }
        .pullToRefresh(topPadding: overlayHeaderHeight) {
            try? await Task.sleep(for: .seconds(1))
            fetchBundleData()
        }
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                if showSearchBar {
                    isSearchFieldFocused = false

                    if !isSearching {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSearchBar = false
                        }
                    }
                }
            }
        )
    }

    private var bundleGrid: some View {
        LazyVGrid(columns: columns, spacing: 11) {
            ForEach(bundleViewModel.sortedBundles, id: \.documentId) { bundle in
                Button {
                    guard NetworkManager.shared.isConnected else {
                        ToastManager.shared.show()
                        return
                    }

                    bundleViewModel.selectedBundle = bundle
                    bundleViewModel.selectedBackground = bundleViewModel.resolveBackground(from: bundle.selectedBackground)
                    bundleViewModel.selectedCarabiner = bundleViewModel.resolveCarabiner(from: bundle.selectedCarabiner)

                    router.push(.bundleDetailView)
                } label: {
                    BundleGridItem(bundle: bundle)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 90)
    }
    
    private var bundleEmptyView: some View {
        VStack {
            Spacer()
                .frame(height: 180)
            
            Image(.emptyViewIcon)
                .resizable()
                .frame(width: 124, height: 111)
            
            Text("공방에서 뭉치를 만들어봐요")
                .typography(.suit15R)
                .padding(.top, 15)
            
            Spacer()
        }
        .padding(.top, 10)
        .scrollIndicators(.hidden)
    }
    
    var collectionHeader: some View {
        HStack(spacing: 0) {
            sortButton
            
            Spacer()
            
            if collectionViewModel.collectionToggle {
                // 보유한 키링 개수
                Text("\(collectionViewModel.keyring.count) / \(collectionViewModel.maxKeyringCount)")
                    .typography(.suit14SB18)
                    .foregroundColor(.black100)
                    .padding(.trailing, 8)

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSearchFieldFocused = false
                        showSearchBar = false
                        
                        showInvenExpandAlert = true
                    }
                }) {
                    Image(.invenPlus)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 21, height: 21)
                }
            } else {
                // 뭉치 탭: 뭉치 만들기 버튼
                Button(action: {
                    router.push(.bundleCreateView)
                }) {
                    HStack(spacing: 8) {
                        Image(.makingIcon)
                        
                        Text("뭉치 만들기")
                            .typography(.suit17B)
                            .foregroundColor(.black100)
                    }
                }
                .frame(width: 129, height: 37)
                .glassEffect(.regular.interactive(), in: .capsule)
            }

        }
    }
    
    // 정렬 버튼
    var sortButton: some View {
        Button(action: {
            showSortSheet = true
        }) {
            HStack(spacing: 2) {
                Text(collectionViewModel.selectedSort)
                    .typography(.suit14SB18)
                    .foregroundColor(.gray500)
                
                Image(.chevronDownGray500)
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, Spacing.gap)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray50)
            )
            
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var emptyView: some View {
        VStack {
            Spacer()
                .frame(height: 180)
            
            Image(.emptyViewIcon)
                .resizable()
                .frame(width: 124, height: 111)
            
            Text(selectedCategory == "전체" ? "공방에서 키링을 만들어봐요" : "해당 태그를 가진 키링이 없어요")
                .typography(.suit15R)
                .padding(.top, 15)
            
            Spacer()
        }
        .padding(.top, 10)
        .scrollIndicators(.hidden)
    }
}
