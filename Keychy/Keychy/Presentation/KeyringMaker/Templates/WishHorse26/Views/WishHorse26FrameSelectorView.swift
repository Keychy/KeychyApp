//
//  WishHorse26FrameSelectorView.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI
import NukeUI

struct WishHorse26FrameSelectorView: View {
    @Bindable var viewModel: WishHorse26VM

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - 프레임 섹션
            Text("프레임")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableFrames) { frame in
                        frameCell(frame: frame)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 80)

            // MARK: - 안장 섹션 (saddle)
            Text("안장")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.bottom, 8)
                .padding(.top, 13)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableSaddles) { saddle in
                        saddleCell(saddle: saddle)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 60)
            
            // MARK: - 컬러 섹션
            Text("갈기")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 13)

            maneColorPalette
                .padding(.leading, 20)

            Spacer()
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
            .fill(.white100)
            .shadow(color: .black.opacity(0.15), radius: 9)
        )
        .background(Color.gray50.ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Frame Cell

    @ViewBuilder
    private func frameCell(frame: Frame) -> some View {
        let isSelected = viewModel.selectedFrame?.id == frame.id

        Button {
            viewModel.selectedFrame = frame
            Task {
                await viewModel.composeHorse()
            }
        } label: {
            VStack(spacing: 6) {
                LazyImage(url: URL(string: frame.thumbnailURL)) { state in
                    if let image = state.image {
                        ZStack {
                            Color.gray50

                            image
                                .resizable()
                                .scaledToFit()
                                .padding(.vertical, 8)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray100)
                            .frame(width: 80, height: 80)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.main500 : Color.clear,
                            lineWidth: 2.5
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Saddle Cell
    
    @ViewBuilder
    private func saddleCell(saddle: Saddle) -> some View {
        let isSelected = viewModel.selectedSaddle?.id == saddle.id

        Button {
            viewModel.selectedSaddle = saddle
            Task {
                await viewModel.composeHorse()
            }
        } label: {
            VStack(spacing: 6) {
                LazyImage(url: URL(string: saddle.thumbnailURL)) { state in
                    if let image = state.image {
                        ZStack {
                            Color.gray50

                            image
                                .resizable()
                                .scaledToFit()
                                .padding(.vertical, 8)
                        }
                        .frame(width: 80, height: 59)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray100)
                            .frame(width: 80, height: 59)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.main500 : Color.clear,
                            lineWidth: 2.5
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Mane Color Palette
    
    /// 갈기 컬러 팔레트
    @ViewBuilder
    private var maneColorPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 11) {
                // 프리셋 색상들
                ForEach(Array(ManeColorType.allCases.enumerated()), id: \.offset) { index, colorType in
                    let color = colorType.color
                    
                    Button {
                        // Firebase에서 정확히 일치하는 색상의 Mane 찾기
                        if let matchingMane = viewModel.availableManes.first(where: { mane in
                            mane.color.uppercased() == colorType.rawValue.uppercased()
                        }) {
                            viewModel.selectedMane = matchingMane
                            Task {
                                await viewModel.composeHorse()
                            }
                        }
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 37, height: 37)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.black20, lineWidth: color == .white ? 1 : 0)
                            )
                            .overlay(
                                ZStack {
                                    Circle()
                                        .strokeBorder(
                                            Color.white,
                                            lineWidth: isColorSelected(colorType) ? 3 : 0
                                        )
                                    
                                    Image(.checkMarkWhite)
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                        .opacity(isColorSelected(colorType) ? 1 : 0)
                                }

                            )
                            .shadow(
                                color: isColorSelected(colorType) ? Color.black.opacity(0.5) : Color.clear,
                                radius: 2
                            )
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Helper
    /// 현재 선택된 색상인지 확인 - selectedMane 기반
    private func isColorSelected(_ colorType: ManeColorType) -> Bool {
        guard let selectedMane = viewModel.selectedMane else {
            return false
        }
        return selectedMane.color.uppercased() == colorType.rawValue.uppercased()
    }
}
