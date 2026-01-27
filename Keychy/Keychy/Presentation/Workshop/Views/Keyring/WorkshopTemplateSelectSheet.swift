//
//  WorkshopTemplateSelectSheet.swift
//  Keychy
//
//  Created by 길지훈 on 1/26/26.
//

import SwiftUI

/// 템플릿 선택 필터 (카테고리)
enum WorkshopTemplateSelectFilter: String, CaseIterable {
    case owned = "마이"
    case free = "무료"
    case image = "이미지"
    case text = "텍스트"
    case drawing = "드로잉"
}

/// 템플릿 정렬 순서
enum WorkshopTemplateSortOrder: String, CaseIterable {
    case latest = "최신순"
    case popular = "인기순"
}

/// 키링 만들기 - 템플릿 선택 시트
struct WorkshopTemplateSelectSheet: View {
    @Binding var isPresented: Bool
    @Bindable var router: NavigationRouter<WorkshopRoute>
    let templates: [KeyringTemplate]

    @Environment(UserManager.self) private var userManager
    @State private var selectedFilter: WorkshopTemplateSelectFilter?
    @State private var sortOrder: WorkshopTemplateSortOrder = .latest

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 15.5), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            // 타이틀
            Text("템플릿 선택")
                .typography(.suit15SB25)
                .padding(.top, 29)
                .padding(.bottom, 22)

            // 필터 바
            filterBar
                .padding(.bottom, 22)

            // 템플릿 그리드 (캐시된 데이터 사용)
            ScrollView(showsIndicators: false) {
                if filteredTemplates.isEmpty {
                    emptyView
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredTemplates, id: \.id) { template in
                            templateCard(template)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(.white100)
        .presentationDetents([.fraction(0.95)])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 카테고리 필터 칩 (상단)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WorkshopTemplateSelectFilter.allCases, id: \.self) { filter in
                        let isSelected = selectedFilter == filter
                        let icon: Image? = filter == .owned
                            ? (isSelected ? Image(.quickFilterOwned) : Image(.quickFilterCheckedOn))
                            : nil

                        filterChip(
                            title: filter.rawValue,
                            isSelected: isSelected,
                            icon: icon
                        ) {
                            // 같은 필터 다시 누르면 해제 (전체)
                            selectedFilter = isSelected ? nil : filter
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }

            // 정렬 메뉴 (하단)
            Menu {
                ForEach(WorkshopTemplateSortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(sortOrder.rawValue)
                        .typography(.suit14SB18)
                        .foregroundColor(.gray500)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray500)
                }
            }
            .padding(.horizontal, 31)
        }
    }

    // MARK: - Filter Chip (카테고리용)
    private func filterChip(
        title: String,
        isSelected: Bool,
        icon: Image? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    icon
                }
                Text(title)
                    .typography(.suit15M)
                    .foregroundColor(isSelected ? .white100 : .main500)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 17)
                    .fill(isSelected ? Color.main500 : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 17)
                    .stroke(Color.main500, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Template Card
    private func templateCard(_ template: KeyringTemplate) -> some View {
        let isOwned = userManager.currentUser?.templates.contains(template.id ?? "") ?? false

        return Button {
            // 템플릿 선택 → 해당 Preview로 이동
            if let route = WorkshopRoute.from(string: template.id ?? "") {
                isPresented = false
                DispatchQueue.main.async {
                    router.push(route)
                }
            }
        } label: {
            VStack(spacing: 8) {
                // 썸네일 + 가격 오버레이 (공방 스타일)
                ZStack(alignment: .top) {
                    SimpleAnimatedImage(url: template.thumbnailURL)
                        .aspectRatio(contentMode: .fit)
                        .padding(.vertical, 10)
                        .clipped()
                        .frame(width: 105, height: 140.61)

                    // 유료/보유 오버레이
                    VStack {
                        HStack {
                            // 유료 아이콘 (왼쪽 상단) - 유료일 때 (보유 여부 상관없이)
                            Image(.myCoinMini)
                                .opacity(template.isFree ? 0 : 1)

                            Spacer()

                            // 보유 뱃지 (오른쪽 상단) - 보유 또는 무료일 때
                            Text("보유")
                                .typography(.suit13M)
                                .foregroundStyle(.white100)
                                .padding(.vertical, 1)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.black60)
                                )
                                .opacity(isOwned || template.isFree ? 1 : 0)
                        }
                        .padding(.top, 6)
                        .padding(.horizontal, 7)
                        Spacer()
                    }
                }
                .frame(width: 105, height: 140.61)
                .background(Color.gray50)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray50, lineWidth: 2)
                )

                // 템플릿 이름
                Text(template.name)
                    .typography(.suit14SB18)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(.emptyViewIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
            Text("템플릿이 없어요")
                .typography(.suit15R)
                .foregroundStyle(.gray400)
        }
        .padding(.top, 100)
    }

    // MARK: - Filtering
    private var filteredTemplates: [KeyringTemplate] {
        var result = templates

        // 1. 카테고리 필터 (nil이면 전체)
        if let filter = selectedFilter {
            switch filter {
            case .free:
                result = result.filter { $0.isFree }
            case .owned:
                let ownedIds = userManager.currentUser?.templates ?? []
                result = result.filter { ownedIds.contains($0.id ?? "") }
            case .image:
                result = result.filter { $0.tags.contains("이미지") }
            case .text:
                result = result.filter { $0.tags.contains("텍스트") }
            case .drawing:
                result = result.filter { $0.tags.contains("드로잉") }
            }
        }

        // 2. 정렬
        switch sortOrder {
        case .latest:
            result.sort { $0.createdAt > $1.createdAt }
        case .popular:
            result.sort { $0.useCount > $1.useCount }
        }

        return result
    }
}
