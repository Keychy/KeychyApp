//
//  UniformFrameSelectorView.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//
//  유니폼 프레임 선택 뷰 (하단 영역)
//  유료 프레임은 가격 뱃지 표시, 미보유 시 카트에 추가
//

import SwiftUI
import NukeUI

struct UniformFrameSelectorView: View {
    @Bindable var viewModel: UniformVM
    @Binding var cartItems: [EffectItem]

    // 임시 @State — 나중에 VM 프로퍼티로 교체 예정
    @State private var uniformColor1: Color = .black
    @State private var uniformColor2: Color = .white
    @State private var selectedColorIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - 프레임 섹션
            VStack(alignment: .leading, spacing: 8) {
                Text("프레임")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)
                    .padding(.leading, 20)
                    .padding(.top, 30)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.availableFrames) { frame in
                            frameCell(frame: frame)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            // MARK: - 컬러 섹션
            VStack(alignment: .leading, spacing: 10) {
                Text("컬러")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)
                    .padding(.leading, 20)

                // 컬러 칩 토글 (컬러 1 / 컬러 2)
                ColorChipSelector(
                    chips: [
                        .init(label: "컬러 1", color: $uniformColor1),
                        .init(label: "컬러 2", color: $uniformColor2)
                    ],
                    selectedIndex: $selectedColorIndex
                )

                // 프리셋 팔레트
                ColorPaletteRow(
                    selectedColor: selectedColorIndex == 0
                        ? $uniformColor1
                        : $uniformColor2
                )
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
        let price = frame.price ?? 0
        let isOwned = viewModel.isFrameOwned(frame)
        let isPaid = price > 0 && !isOwned
        let showCoinBadge = isPaid && !isSelected

        Button {
            selectFrame(frame)
        } label: {
            VStack(spacing: 0) {
                LazyImage(url: URL(string: frame.thumbnailURL)) { state in
                    if let image = state.image {
                        ZStack {
                            Color.gray50
                            image.padding(5)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray50)
                            .frame(width: 80, height: 80)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.main500 : Color.clear,
                            lineWidth: 2.0
                        )
                )
                .overlay(alignment: .topTrailing) {
                    if showCoinBadge {
                        Image(.myCoinMini)
                            .padding(2)
                            .offset(x: 4, y: -4)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Frame Selection Logic
    private func selectFrame(_ frame: Frame) {
        let price = frame.price ?? 0
        let isOwned = viewModel.isFrameOwned(frame)

        viewModel.selectedFrame = frame

        if price > 0 && !isOwned {
            cartItems.removeAll { $0.type == .uniformFrame }
            cartItems.append(EffectItem(uniformFrame: frame, price: price))
        } else {
            cartItems.removeAll { $0.type == .uniformFrame }
        }
    }
}
