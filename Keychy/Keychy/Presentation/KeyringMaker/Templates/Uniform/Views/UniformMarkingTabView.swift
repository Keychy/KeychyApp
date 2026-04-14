//
//  UniformMarkingTabView.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-13.
//
//  마킹 탭 하단 컨트롤 (세그먼트 + 텍스트 입력 + 슬라이더 + 컬러)
//

import SwiftUI

struct UniformMarkingTabView: View {
    @Bindable var viewModel: UniformVM

    @State private var selectedSegment: Int = 0       // 0: 선수이름, 1: 등번호
    @State private var selectedColorIndex: Int = 0    // 4칩 중 선택된 인덱스

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            markingSection
            colorSection
            Spacer()
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
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
}

// MARK: - 마킹 섹션
extension UniformMarkingTabView {

    @ViewBuilder
    private var markingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("마킹")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 30)

            // 세그먼트 토글
            segmentToggle

            // 텍스트 입력 필드
            markingTextField

            // 텍스트 곡률 슬라이더 (선수 이름일 때만 표시, 등번호일 때는 자리 유지)
            curvatureSlider
                .opacity(selectedSegment == 0 ? 1 : 0)
        }
    }
}

// MARK: - 세그먼트 토글
extension UniformMarkingTabView {

    @ViewBuilder
    private var segmentToggle: some View {
        HStack(spacing: 8) {
            segmentButton(title: "선수 이름", index: 0)
            segmentButton(title: "등번호", index: 1)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func segmentButton(title: String, index: Int) -> some View {
        let isSelected = selectedSegment == index

        Button {
            selectedSegment = index
            Haptic.impact(style: .light)
        } label: {
            Text(title)
                .typography(.suit15M)
                .foregroundStyle(isSelected ? .white100 : .gray500)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .main500 : .gray50)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 텍스트 입력 필드
extension UniformMarkingTabView {

    @ViewBuilder
    private var markingTextField: some View {
        // selectedSegment에 따라 바인딩과 placeholder 변경
        if selectedSegment == 0 {
            TextField("선수 이름을 입력해주세요.", text: $viewModel.playerNameText)
                .typography(.suit15M)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.gray50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .onChange(of: viewModel.playerNameText) { _, newValue in
                    viewModel.validatePlayerName(newValue)
                }
        } else {
            TextField("등번호를 입력해주세요.", text: $viewModel.numberText)
                .typography(.suit15M)
                .keyboardType(.numberPad)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.gray50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .onChange(of: viewModel.numberText) { _, newValue in
                    viewModel.validateNumberText(newValue)
                }
        }
    }
}

// MARK: - 텍스트 곡률 슬라이더
extension UniformMarkingTabView {

    @ViewBuilder
    private var curvatureSlider: some View {
        HStack(spacing: 15) {
            Image(.flatText)

            VStack(spacing: 0) {
                Slider(value: $viewModel.textCurvature, in: 0.16...0.84)
                    .tint(.main500)
                    .padding(.bottom, -3)

                // 슬라이더 트랙에 맞춘 5칸 눈금
                GeometryReader { geo in
                    let thumbInset: CGFloat = 14
                    let trackWidth = geo.size.width - thumbInset * 2

                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color(hex: "3C3C43").opacity(0.18))
                            .frame(width: 4, height: 4)
                            .position(
                                x: thumbInset + trackWidth * CGFloat(i) / 4.0,
                                y: 2
                            )
                    }
                }
                .frame(height: 4)
            }

            Image(.bentText)
        }
        .padding(.horizontal, 25)
    }
}

// MARK: - 컬러 섹션
extension UniformMarkingTabView {

    @ViewBuilder
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("컬러")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)

            // 4칩 컬러 선택 (가로 스크롤)
            ScrollView(.horizontal, showsIndicators: false) {
                ColorChipSelector(
                    chips: [
                        .init(label: "선수이름", color: $viewModel.nameInnerColor),
                        .init(label: "테두리", color: $viewModel.nameOutlineColor),
                        .init(label: "등번호", color: $viewModel.numberInnerColor),
                        .init(label: "테두리", color: $viewModel.numberOutlineColor)
                    ],
                    selectedIndex: $selectedColorIndex
                )
            }

            // 선택된 칩에 따라 팔레트 바인딩 변경
            ColorPaletteRow(
                selectedColor: colorBinding(for: selectedColorIndex)
            )
        }
    }

    /// 칩 인덱스에 따라 적절한 Color Binding 반환
    private func colorBinding(for index: Int) -> Binding<Color> {
        switch index {
        case 0: return $viewModel.nameInnerColor
        case 1: return $viewModel.nameOutlineColor
        case 2: return $viewModel.numberInnerColor
        case 3: return $viewModel.numberOutlineColor
        default: return $viewModel.nameInnerColor
        }
    }
}
