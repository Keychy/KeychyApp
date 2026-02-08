//
//  CollectionView+SearchMode.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

// MARK: - 검색 관련
extension CollectionView {
    // MARK: - Search Mode View
    var searchModeView: some View {
        Group {
            if collectionViewModel.hasNetworkError {
                // 네트워크 에러: 오버레이 형태
                networkErrorView
            } else {
                // 정상 상태: 기존 VStack 형태
                VStack(spacing: 10) {
                    // 헤더
                    searchHeaderSection
                    
                    // 세그먼트 컨트롤
                    searchSegmentControl
                        .padding(.horizontal, Spacing.margin)
                    
                    // 결과 카운트
                    searchResultCount
                    
                    // 컨텐츠
                    searchContentSection
                        .padding(.top, -4)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSearchFieldFocused {
                        isSearchFieldFocused = false
                    }
                }
            }
        }
    }
    
    // 검색 헤더
    private var searchHeaderSection: some View {
        HStack {
            Text("검색")
                .typography(.nanum24EB)
                .foregroundColor(.black100)
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.top, 60)
        .padding(.leading, 16)
    }
    
    // 세그먼트 컨트롤
    private var searchSegmentControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "키링", segment: .keyring)
            segmentButton(title: "뭉치", segment: .bundle)
        }
        .frame(height: 46)
        .background(Color.gray50)
        .cornerRadius(100)
    }
    
    private func segmentButton(title: String, segment: SearchSegment) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                searchSegment = segment
            }
        } label: {
            Text(title)
                .typography(.suit16M)
                .foregroundColor(.black100)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    searchSegment == segment ?
                        .white100 : .clear
                )
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .padding(4)
    }
    
    // 결과 카운트
    private var searchResultCount: some View {
        HStack {
            Text("\(currentSearchResultCount)개 발견됨")
                .typography(.suit14M)
                .foregroundColor(.gray500)
                .padding(.top, 10)
                .padding(.leading, 22)
            
            Spacer()
        }
    }
    
    private var currentSearchResultCount: Int {
        switch searchSegment {
        case .keyring:
            return filteredKeyrings.count
        case .bundle:
            return filteredBundles.count
        }
    }
    
    var searchContentSection: some View {
        Group {
            if searchSegment == .keyring {
                keyringSearchResults
            } else {
                bundleSearchResults
            }
        }
    }
    
    // 키링 검색 결과
    private var keyringSearchResults: some View {
        ScrollView {
            VStack(spacing: 0) {
                if filteredKeyrings.isEmpty {
                    searchEmptyView
                } else {
                    collectionGridView(keyrings: filteredKeyrings)
                }
            }
            .padding(.horizontal, Spacing.xs)
        }
        .scrollIndicators(.hidden)
        .simultaneousGesture(scrollGesture)
    }
    
    // 뭉치 검색 결과
    private var bundleSearchResults: some View {
        ScrollView {
            VStack(spacing: 0) {
                if filteredBundles.isEmpty {
                    searchEmptyView
                } else {
                    bundleSearchGrid
                }
            }
            .padding(.horizontal, Spacing.xs)
        }
        .scrollIndicators(.hidden)
        .simultaneousGesture(scrollGesture)
    }
    
    private var bundleSearchGrid: some View {
        LazyVGrid(columns: columns, spacing: 11) {
            ForEach(filteredBundles, id: \.documentId) { bundle in
                Button {
                    guard NetworkManager.shared.isConnected else {
                        ToastManager.shared.show()
                        return
                    }
                    
                    // 키보드 내리기
                    if isSearchFieldFocused {
                        isSearchFieldFocused = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        bundleViewModel.selectedBundle = bundle
                        bundleViewModel.selectedBackground = bundleViewModel.resolveBackground(from: bundle.selectedBackground)
                        bundleViewModel.selectedCarabiner = bundleViewModel.resolveCarabiner(from: bundle.selectedCarabiner)
                        router.push(.bundleDetailView)
                    }
                } label: {
                    BundleGridItem(
                        bundle: bundle,
                        searchKeyword: searchText
                    )
                    
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.gap)
        .padding(.vertical, 4)
        .padding(.bottom, 90)
    }
    
    // 스크롤 제스처
    private var scrollGesture: some Gesture {
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
            
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    searchHeaderSection
                    
                    searchSegmentControl
                        .padding(.horizontal, Spacing.margin)
                    
                    searchResultCount
                    
                    Spacer()
                }
                .background(Color.white)
            }
        }
    }

    
    var searchEmptyView: some View {
        VStack {
            Spacer()
                .frame(height: 180)
            
            Image(.emptyViewIcon)
                .resizable()
                .frame(width: 124, height: 111)
            
            Text("검색 결과가 없어요.")
                .typography(.suit15R)
                .padding(.top, 15)
            
            Spacer()
        }
        .padding(.top, 10)
        .scrollIndicators(.hidden)
    }
    
    // 검색바 뷰 - 하단에 고정되며 키보드와 함께 움직임
    var searchBarView: some View {
        HStack(spacing: 12) {
            HStack {
                Image(.searchIcon)
                    .resizable()
                    .frame(width: 28, height: 28)
                
                TextField("검색어를 입력해주세요", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.automatic)
                    .typography(.notosans16R)
                    .tint(.main500)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onSubmit {
                        if searchText.isEmpty {
                            isSearchFieldFocused = false
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSearchBar = false
                            }
                        }
                    }
            }
            .padding(10)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 296))
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            
            Button(action: {
                // 키보드 먼저 내리기
                isSearchFieldFocused = false
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSearchBar = false
                }
            }) {
                Image(.dismiss)
                    .foregroundColor(.primary)
            }
            .frame(width: 48, height: 48)
            .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .frame(height: 48)
    }
    
    // MARK: - 검색 키워드 Highlighted Text
    func highlightedText(text: String, keyword: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        guard !keyword.isEmpty else {
            return attributedString
        }
        
        attributedString.font = .notosans14M
        
        let lowerText = text.lowercased()
        let lowerKeyword = keyword.lowercased()
        
        var searchRange = lowerText.startIndex..<lowerText.endIndex
        
        while let range = lowerText.range(of: lowerKeyword, range: searchRange) {
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: lowerText.distance(from: lowerText.startIndex, to: range.lowerBound))
            let endIndex = attributedString.index(startIndex, offsetByCharacters: lowerKeyword.count)
            let attributedRange = startIndex..<endIndex
            
            attributedString[attributedRange].foregroundColor = .main500
            attributedString[attributedRange].font = .notosans14SB
            
            searchRange = range.upperBound..<lowerText.endIndex
        }
        
        return attributedString
    }
}

extension UISegmentedControl {
  override open func didMoveToSuperview() {
     super.didMoveToSuperview()
     self.setContentHuggingPriority(.defaultLow, for: .vertical)
   }
}
