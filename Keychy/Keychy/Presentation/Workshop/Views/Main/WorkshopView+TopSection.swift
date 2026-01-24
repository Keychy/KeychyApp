//
//  WorkshopView+TopSection.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - Top Section

extension WorkshopView {
    /// 상단 배너 (코인 버튼 + 타이틀)
    var topBannerSection: some View {
        HStack {
            titleView
            Spacer()
            makeBtn
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }
    
    /// 스크롤 시 나타나는 상단 타이틀 바
    var topTitleBar: some View {
        HStack {
            titleView
            Spacer()
            myItemBtn
        }
        .padding(.top, WorkshopLayout.topPadding)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(Color.white100)
        .opacity(viewModel.mainContentOffset - WorkshopLayout.titleBarOpacityThreshold < WorkshopLayout.titleBarOpacityRange ? 1 : 0)
    }
    
    /// 타이틀 뷰
    var titleView: some View {
        HStack(spacing: 10) {
            Button {
                // TODO: - 공방 탭 액션
                workshopToggle = true
            } label: {
                Text("키링")
                    .typography(.nanum24EB)
                    .foregroundStyle(workshopToggle ? .black100 : .gray100)
            }
            
            Button {
                // TODO: - 뭉치 탭 액션
                workshopToggle = false
            } label: {
                Text("뭉치")
                    .typography(.nanum24EB)
                    .foregroundStyle(workshopToggle ? .gray100 : .black100)
            }
        }
    }
    
    /// 내 아이템 버튼
    var myItemBtn: some View {
        Button {
            router.push(.myItems)
        } label: {
            HStack(spacing: 0) {
                Image(.myItem)
                    .resizable()
                    .scaledToFit()

                Spacer()

                Text("내 아이템")
                    .typography(.suit17B)
                    .foregroundColor(.black)
            }
        }
        .frame(minWidth: 80)
        .frame(height: 44)
        .fixedSize(horizontal: true, vertical: true)
        .buttonStyle(.glass)
    }

    /// 만들기 메뉴 버튼
    var makeBtn: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMakeMenu.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(.makingIcon)
                Text("만들기")
                    .typography(.suit17B)
                    .foregroundStyle(.black100)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.glass)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        makeMenuPosition = geo.frame(in: .global)
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newValue in
                        makeMenuPosition = newValue
                    }
            }
        )
    }

    /// 상단 그라데이션 오버레이
    var topGradientOverlay: some View {
        VStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.8),
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: WorkshopLayout.gradientHeight)
            .ignoresSafeArea(edges: .top)
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    /// 최근 사용 템플릿 섹션
    var recentTemplateSection: some View {
        WorkshopRecentTemplate(
            templates: viewModel.recentTemplates,
            isLoading: viewModel.isLoading
        ) { template in
            // 템플릿 상세 프리뷰로 이동
            router.push(.workshopPreview(item: template))
        }
    }
}
