//
//  WorkshopRecentTemplate.swift
//  Keychy
//
//  Created by 길지훈 on 1/21/26.
//

import SwiftUI
import NukeUI

// MARK: - 최근 사용 템플릿 섹션

struct WorkshopRecentTemplate: View {
    let templates: [KeyringTemplate]
    let isLoading: Bool
    var onTemplateTap: ((KeyringTemplate) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 타이틀
            Text("최근 사용 템플릿")
                .typography(.suit17B)
                .foregroundColor(.black100)
                .padding(.horizontal, 20)

            // 콘텐츠
            if isLoading {
                loadingView
            } else if templates.isEmpty {
                recentEmptyView
            } else {
                templateScrollView
            }
        }
    }

    // MARK: - 로딩 뷰

    private var loadingView: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonBox(width: 112, height: 112)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 빈 상태 뷰
    private var recentEmptyView: some View {
        HStack {
            Spacer()
            Text("키링을 만들면 최근 사용한 템플릿이 이곳에 표시됩니다")
                .typography(.suit14R18)
                .foregroundColor(.gray500)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white70)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray50, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - 템플릿 스크롤 뷰

    private var templateScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(templates, id: \.id) { template in
                    RecentTemplateCard(template: template) {
                        onTemplateTap?(template)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - 개별 템플릿 카드
private struct RecentTemplateCard: View {
    let template: KeyringTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                LazyImage(url: URL(string: template.thumbnailURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if state.isLoading {
                        LoadingAlert(type: .short30, message: nil)
                    } else {
                        Color.gray50
                            .frame(width: 112, height: 112)
                    }
                }
                .padding(5)

                // 유료 아이콘
                if !template.isFree {
                    VStack {
                        HStack {
                            Image(.myCoinMini)
                            
                            Spacer()
                        }
                        .padding(.top, 7)
                        .padding(.leading, 7)
                        Spacer()
                    }
                }
            }
            .frame(width: 112, height: 112)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.gray50, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("로딩 상태") {
    WorkshopRecentTemplate(
        templates: [],
        isLoading: true
    )
}

#Preview("빈 상태") {
    WorkshopRecentTemplate(
        templates: [],
        isLoading: false
    )
}
