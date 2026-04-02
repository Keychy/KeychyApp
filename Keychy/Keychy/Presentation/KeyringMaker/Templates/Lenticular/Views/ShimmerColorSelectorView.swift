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
struct StyleSelectorView: View {
    @Bindable var viewModel: LenticularVM

    // 애니메이션 (매트릭스/글리터 미리보기용)
    @State private var matrixPhase: Double = 0
    @State private var cosmosPhase: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            styleSection(
                title: "광택 효과",
                presets: ShimmerColorPreset.shimmerPresets,
                selected: viewModel.selectedShimmerColor,
                tintBinding: shimmerTintBinding(),
                onSelect: { viewModel.updateShimmerColor($0) }
            )

            styleSection(
                title: "테두리",
                presets: ShimmerColorPreset.borderPresets,
                selected: viewModel.selectedBorderColor,
                tintBinding: borderTintBinding(),
                onSelect: { viewModel.updateBorderColor($0) }
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

    // MARK: - 틴트 색상 바인딩
    /// ColorPicker ↔ VM 연결: get은 현재 셰이더 색상, set은 .customTint 생성
    private func shimmerTintBinding() -> Binding<Color> {
        Binding(
            get: {
                let c = viewModel.selectedShimmerColor.shaderColor
                return Color(red: Double(c.r), green: Double(c.g), blue: Double(c.b))
            },
            set: { newColor in
                let mode = viewModel.selectedShimmerColor.activePreset
                guard mode != .hologram else { return }
                let c = UIColor(newColor).rgbComponents
                viewModel.updateShimmerColor(.customTint(mode: mode, r: c.r, g: c.g, b: c.b))
            }
        )
    }

    private func borderTintBinding() -> Binding<Color> {
        Binding(
            get: {
                let c = viewModel.selectedBorderColor.shaderColor
                return Color(red: Double(c.r), green: Double(c.g), blue: Double(c.b))
            },
            set: { newColor in
                let mode = viewModel.selectedBorderColor.activePreset
                guard mode != .hologram else { return }
                let c = UIColor(newColor).rgbComponents
                viewModel.updateBorderColor(.customTint(mode: mode, r: c.r, g: c.g, b: c.b))
            }
        )
    }
}

// MARK: - 섹션 뷰
extension StyleSelectorView {
    @ViewBuilder
    private func styleSection(
        title: String,
        presets: [ShimmerColorPreset],
        selected: KeyringAppearanceColor,
        tintBinding: Binding<Color>,
        onSelect: @escaping (KeyringAppearanceColor) -> Void
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
                            presetCell(
                                preset: preset,
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

    /// 틴트 색상 피커 — 홀로그램 선택 시 비활성화
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

// MARK: - 프리셋 셀
extension StyleSelectorView {
    @ViewBuilder
    private func presetCell(
        preset: ShimmerColorPreset,
        isSelected: Bool,
        onSelect: @escaping (KeyringAppearanceColor) -> Void
    ) -> some View {
        Button {
            onSelect(.preset(preset))
        } label: {
            VStack(spacing: 6) {
                presetCircle(for: preset)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle().strokeBorder(Color.black20, lineWidth: 0.5)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(.main500, lineWidth: isSelected ? 2.5 : 0)
                            .frame(width: 46, height: 46)
                    )

                Text(preset.displayName)
                    .typography(.suit12M)
                    .foregroundStyle(isSelected ? .black100 : .gray300)
            }
        }
    }

    /// 프리셋 타입별 미리보기
    @ViewBuilder
    private func presetCircle(for preset: ShimmerColorPreset) -> some View {
        switch preset {
        case .silver:
            Circle().fill(Color(preset.previewColor))

        case .hologram:
            Circle().fill(
                AngularGradient(
                    colors: [Color.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red]
                        .map { $0.opacity(0.7) },
                    center: .center
                )
            )

        case .liquid:
            // 크롬 반사 미리보기: 밝은 하이라이트 + 어두운 그림자
            Circle().fill(
                RadialGradient(
                    colors: [
                        .white,
                        Color(red: 0.90, green: 0.92, blue: 0.95),
                        Color(red: 0.45, green: 0.47, blue: 0.52),
                        Color(red: 0.15, green: 0.16, blue: 0.18)
                    ],
                    center: .init(x: 0.35, y: 0.3),
                    startRadius: 1,
                    endRadius: 22
                )
            )

        case .pulse:
            // 펄스 미리보기: 밝은 스윕 + 어두운 배경
            Circle().fill(
                AngularGradient(
                    stops: [
                        .init(color: .white.opacity(0.95), location: 0.0),
                        .init(color: Color(red: 0.45, green: 0.55, blue: 0.90).opacity(0.5), location: 0.12),
                        .init(color: Color(red: 0.15, green: 0.18, blue: 0.35).opacity(0.3), location: 0.25),
                        .init(color: Color(red: 0.10, green: 0.12, blue: 0.25), location: 0.5),
                        .init(color: Color(red: 0.10, green: 0.12, blue: 0.25), location: 0.88),
                        .init(color: .white.opacity(0.5), location: 1.0)
                    ],
                    center: .center
                )
            )

        case .matrix:
            ZStack {
                Circle().fill(Color(red: 0.02, green: 0.08, blue: 0.02))
                matrixOverlay.clipShape(Circle())
            }

        case .cosmos:
            ZStack {
                Circle().fill(Color(red: 0.06, green: 0.08, blue: 0.22))
                cosmosOverlay.clipShape(Circle())
            }
        }
    }

    /// 매트릭스 미리보기 오버레이 (디지털 레인)
    private var matrixOverlay: some View {
        Canvas { context, size in
            let cols: [(CGFloat, CGFloat, Double)] = [
                (0.12, 0.55, 0.0), (0.30, 0.70, 0.7), (0.50, 0.85, 0.3),
                (0.68, 0.50, 1.1), (0.88, 0.65, 0.5),
            ]
            for (_, col) in cols.enumerated() {
                let phase = sin(matrixPhase * .pi + col.2) * 0.5 + 0.5
                let x = col.0 * size.width
                let trailLen = col.1 * size.height * 0.5
                let headY = CGFloat(1.0 - phase) * (size.height - trailLen)

                let headRect = CGRect(x: x - 1.5, y: headY, width: 3, height: 3)
                context.fill(
                    Path(ellipseIn: headRect),
                    with: .color(Color(red: 0.5, green: 1.0, blue: 0.7).opacity(0.9))
                )

                let steps = 5
                for step in 0..<steps {
                    let t = CGFloat(step + 1) / CGFloat(steps + 1)
                    let fade = Double(1.0 - t)
                    let sy = headY + t * trailLen
                    let rect = CGRect(x: x - 1.2, y: sy, width: 2.5, height: 2.5)
                    context.fill(Path(rect), with: .color(Color.green.opacity(fade * 0.8)))
                }
            }
        }
    }

    /// 우주 미리보기 오버레이
    private var cosmosOverlay: some View {
        Canvas { context, size in
            let stars: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (0.25, 0.2, 2.5, 0.60), (0.7, 0.15, 3.5, 0.55),
                (0.5, 0.5, 4.5, 0.70), (0.15, 0.6, 2.5, 0.58),
                (0.8, 0.55, 3.0, 0.65), (0.4, 0.8, 3.0, 0.62),
                (0.65, 0.75, 4.0, 0.55), (0.3, 0.35, 2.5, 0.68),
                (0.88, 0.85, 3.5, 0.58),
            ]
            for (i, s) in stars.enumerated() {
                let phase = sin(cosmosPhase * .pi + Double(i) * 0.9) * 0.5 + 0.5
                let opacity = 0.4 + phase * 0.6
                let radius = s.2
                let rect = CGRect(
                    x: s.0 * size.width - radius / 2,
                    y: s.1 * size.height - radius / 2,
                    width: radius, height: radius
                )
                let starColor = Color(
                    hue: s.3,
                    saturation: 0.3 * (1.0 - phase * 0.5),
                    brightness: 0.7 + phase * 0.3
                )
                context.fill(Path(ellipseIn: rect), with: .color(starColor.opacity(opacity)))
            }
        }
    }
}

// MARK: - UIColor RGB 추출 헬퍼
private extension UIColor {
    var rgbComponents: (r: Float, g: Float, b: Float) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: nil)
        return (Float(r), Float(g), Float(b))
    }
}
