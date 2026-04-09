//
//  StyleSelectorView.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-01.
//

import SwiftUI

// MARK: - 렌티큘러 스타일 선택 뷰
/// 커스터마이징 하단 영역: "광택 효과" + "테두리" 2섹션
/// - 왼쪽 ColorPicker: 선택된 프리셋의 틴트 색상 조절 (홀로그램일 때 비활성화)
/// - 오른쪽 스크롤: 프리셋 선택 (메탈릭 | 홀로그램 | 매트릭스 등)
/// - 비-silver 프리셋은 유료 → 미보유 시 카트에 추가됨
struct StyleSelectorView: View {
    @Bindable var viewModel: LenticularVM
    @Binding var cartItems: [EffectItem]

    // 애니메이션 (매트릭스/글리터 미리보기용, +Previews에서 접근)
    @State var matrixPhase: Double = 0
    @State var cosmosPhase: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            styleSection(
                title: "광택 효과",
                section: .shimmer,
                presets: KeyringStylePreset.shimmerPresets,
                selected: viewModel.selectedShimmerEffect,
                tintBinding: shimmerTintBinding(),
                onSelect: { viewModel.selectShimmerEffect(preset: $0, cartItems: $cartItems) }
            )

            styleSection(
                title: "테두리",
                section: .border,
                presets: KeyringStylePreset.borderPresets,
                selected: viewModel.selectedBorderEffect,
                tintBinding: borderTintBinding(),
                onSelect: { viewModel.selectBorderEffect(preset: $0, cartItems: $cartItems) }
            )

            Spacer()
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
            .fill(.white100)
            .shadow(color: .black.opacity(0.15), radius: 9)
            .ignoresSafeArea(edges: .bottom)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                matrixPhase = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                cosmosPhase = 1.0
            }
        }
    }

    // MARK: - 틴트 색상 바인딩 (VM 메서드를 래핑한 SwiftUI Binding)
    /// ColorPicker ↔ VM 연결: get/set 모두 VM 메서드 호출만 함
    private func shimmerTintBinding() -> Binding<Color> {
        Binding(
            get: { viewModel.shimmerTintColor() },
            set: { viewModel.updateShimmerTint(color: $0) }
        )
    }

    private func borderTintBinding() -> Binding<Color> {
        Binding(
            get: { viewModel.borderTintColor() },
            set: { viewModel.updateBorderTint(color: $0) }
        )
    }
}

// MARK: - 섹션 뷰
extension StyleSelectorView {
    @ViewBuilder
    func styleSection(
        title: String,
        section: StyleSection,
        presets: [KeyringStylePreset],
        selected: KeyringAppearanceColor,
        tintBinding: Binding<Color>,
        onSelect: @escaping (KeyringStylePreset) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 20)

            HStack(alignment: .top, spacing: 0) {
                // 왼쪽: 틴트 ColorPicker + "색상" 라벨
                tintPickerView(selected: selected, tintBinding: tintBinding)
                    .padding(.leading, 20)
                    .padding(.trailing, 12)

                // divider
                Rectangle()
                    .fill(.gray50)
                    .frame(width: 3, height: 40)
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.top, 3)

                // 오른쪽: 프리셋 스크롤
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(presets) { preset in
                            presetCellWrapper(
                                preset: preset,
                                section: section,
                                isSelected: selected.activePreset == preset,
                                onSelect: onSelect
                            )
                        }
                    }
                    .padding(.top, 3)
                    .padding(.leading, 12)
                    .padding(.trailing, 20)
                }
            }
        }
    }

    /// presetCell 래퍼 — VM에 소유 상태를 위임하고 셀에 주입
    @ViewBuilder
    private func presetCellWrapper(
        preset: KeyringStylePreset,
        section: StyleSection,
        isSelected: Bool,
        onSelect: @escaping (KeyringStylePreset) -> Void
    ) -> some View {
        let isOwned = section == .shimmer
            ? viewModel.isShimmerOwned(preset)
            : viewModel.isBorderOwned(preset)

        presetCell(
            preset: preset,
            isSelected: isSelected,
            isOwned: isOwned,
            onSelect: onSelect
        )
    }

    /// 틴트 색상 피커 — 홀로그램 선택 시 비활성화 (silver만 보유해도 항상 활성화)
    @ViewBuilder
    private func tintPickerView(
        selected: KeyringAppearanceColor,
        tintBinding: Binding<Color>
    ) -> some View {
        let isHologram = selected.activePreset == .hologram

        VStack(spacing: 6) {
            if isHologram {
                // 비활성 상태: 회색 원
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle().strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        // 비활성 표시 (대각선)
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.gray300)
                    )
            } else {
                ColorPicker("", selection: tintBinding, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 40, height: 40)
            }

            Text("색상")
                .typography(.suit12M)
                .foregroundStyle(
                    isHologram ? .gray200 :
                        (selected.isCustomTint ? .black100 : .gray300)
                )
        }
    }
}
