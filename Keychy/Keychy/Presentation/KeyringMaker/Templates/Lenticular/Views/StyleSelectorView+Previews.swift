//
//  StyleSelectorView+Previews.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-01.
//

import SwiftUI

// MARK: - 프리셋 셀
extension StyleSelectorView {
    /// 프리셋 셀 — 미보유 유료 시각 표시
    /// - 무료 또는 보유 + 선택됨 → `.main500` 테두리 (기존)
    /// - 미보유 유료 + 선택됨(카트 대기) → 그라데이션 테두리
    /// - 미보유 유료 + 미선택 → 우상단에 작은 코인 아이콘 (가격 숫자는 카트에서 확인)
    @ViewBuilder
    func presetCell(
        preset: KeyringStylePreset,
        isSelected: Bool,
        isOwned: Bool,
        onSelect: @escaping (KeyringStylePreset) -> Void
    ) -> some View {
        // 시각 분기 (EffectSelectorView 패턴 차용)
        let isPaid = !preset.isFree && !isOwned
        let isPaidUnownedSelected = isPaid && isSelected   // 카트 대기 상태
        let showCoinBadge = isPaid

        Button {
            onSelect(preset)
        } label: {
            VStack(spacing: 6) {
                presetCircle(for: preset)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle().strokeBorder(Color.black20, lineWidth: 0.5)
                    )
                    .overlay(
                        // 선택 테두리: 카트 대기 = gradient, 그 외 = main500
                        Group {
                            if isPaidUnownedSelected {
                                Circle()
                                    .strokeBorder(.gradient(.primary), lineWidth: 2.5)
                                    .frame(width: 46, height: 46)
                            } else if isSelected {
                                Circle()
                                    .strokeBorder(.main500, lineWidth: 2.5)
                                    .frame(width: 46, height: 46)
                            }
                        }
                    )
                    .overlay(alignment: .topTrailing) {
                        // 코인 아이콘 뱃지: 미보유 유료 + 미선택 시
                        if showCoinBadge {
                            Image(.myCoinMini)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .padding(2)
                                .offset(x: 4, y: -4)
                        }
                    }

                Text(preset.displayName)
                    .typography(.suit12M)
                    .foregroundStyle(isSelected ? .black100 : .gray300)
            }
        }
    }

    /// 프리셋 타입별 미리보기 원형
    @ViewBuilder
    func presetCircle(for preset: KeyringStylePreset) -> some View {
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
    var matrixOverlay: some View {
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

    /// 글리터 미리보기 오버레이 (별 반짝임)
    var cosmosOverlay: some View {
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
