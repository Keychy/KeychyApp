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
        VStack(alignment: .leading, spacing: 16) {
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
            .frame(height: 94)

            // MARK: - 안장 섹션 (saddle)
            Text("안장")
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
            .frame(height: 94)
            
            // MARK: - 컬러 섹션
            VStack(alignment: .leading, spacing: 2) {
                Text("갈기")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)
                    .padding(.leading, 20)

                ManeColorPalette(selectedColor: $viewModel.selectedColor)
                    .padding(.leading, 16)
            }

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
                        .frame(width: 105, height: 105)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray100)
                            .frame(width: 105, height: 105)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.main500 : Color.clear,
                            lineWidth: 2.5
                        )
                )

                // 프레임 이름
                Text(frame.name)
                    .typography(isSelected ? .notosans12SB : .notosans12M)
                    .foregroundStyle(isSelected ? .main500 : .black100)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 70)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 갈기 컬러 팔레트
struct ManeColorPalette: View {
    @Binding var selectedColor: Color

    /// 프리셋 색상들
    private let presetColors: [Color] = [
        Color(hex: "#810A15"),
        Color(hex: "#810A15"),
        Color(hex: "#FF383C"),
        Color(hex: "#FDF1BC"),
        Color(hex: "#FFBAE7"),
        Color(hex: "#C2BCFE")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 11) {
                // ColorPicker
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .frame(width: 37, height: 37)

                // 프리셋 색상들
                ForEach(presetColors, id: \.self) { color in
                    Button {
                        selectedColor = color
                        Haptic.impact(style: .light)
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 37, height: 37)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.black20, lineWidth: color == .white ? 1 : 0)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .shadow(color: selectedColor == color ? Color.black.opacity(0.5) : Color.clear, radius: 2)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        }
    }
}
