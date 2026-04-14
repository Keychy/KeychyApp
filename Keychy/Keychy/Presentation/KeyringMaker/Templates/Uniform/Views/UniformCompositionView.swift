//
//  UniformCompositionView.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//
//  유니폼 5레이어 mask 합성 프리뷰 (프레임/마킹 탭 공용)
//

import SwiftUI
import NukeUI
import Nuke

struct UniformCompositionView: View {
    @Bindable var viewModel: UniformVM
    let onSceneReady: () -> Void

    @Environment(\.previewScaleFactor) private var previewScale
    @Environment(\.previewTopPadding) private var topPadding
    @State private var isFrameLoaded: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    ZStack(alignment: .top) {
                        VStack {
                            Spacer()
                                .frame(height: 135 * previewScale)

                            compositionView
                                .offset(x: 1)
                        }

                        // 체인 이미지 (위에 겹침)
                        Image(.frameChain)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90 * previewScale)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, topPadding)
                .opacity(isFrameLoaded ? 1 : 0)

                if !isFrameLoaded {
                    LoadingAlert(type: .short40, message: nil)
                }
            }
        }
        .onAppear {
            onSceneReady()
        }
    }

    // MARK: - Composition View

    @ViewBuilder
    private var compositionView: some View {
        ZStack(alignment: .center) {
            if let frame = viewModel.selectedFrame {
                let uniformType = frame.uniformType ?? "base"

                // 아크릴이 전체 크기를 결정하고, 나머지는 그 위에 정렬
                ZStack {
                    // 1. 아크릴 (입체감/그림자) — ZStack 크기 기준
                    Image("\(uniformType)_arcylic")
                        .resizable()
                        .frame(width: 302.03 * previewScale, height: 254.16 * previewScale)

                    // 2~5: 유니폼 레이어 (고정 크기로 아크릴 위에 정렬)
                    let layerSize = CGSize(width: 280 * previewScale, height: 205.5 * previewScale)

                    Group {
                        // 2. Color2 + base mask (베이스 영역)
                        Rectangle()
                            .fill(viewModel.uniformColor2)
                            .mask {
                                Image("\(uniformType)_base")
                                    .resizable()
                                    .scaledToFit()
                            }

                        // 3. Color1 + pattern mask (Firebase 패턴)
                        LazyImage(url: URL(string: frame.frameURL)) { state in
                            if let image = state.image {
                                Rectangle()
                                    .fill(viewModel.uniformColor1)
                                    .mask {
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .onAppear {
                                        isFrameLoaded = true
                                    }
                            }
                        }

                        // 4. stroke (외곽선)
                        Image("\(uniformType)_stroke")
                            .resizable()
                            .scaledToFit()

                        // 5. 텍스트 오버레이 (등번호 + 이름)
                        uniformTextOverlay(frame: frame)
                    }
                    .frame(width: layerSize.width, height: layerSize.height)
                    .offset(y: 14 * previewScale)
                    .offset(x: -2 * previewScale)
                }
                .onDisappear {
                    isFrameLoaded = false
                }
            }
        }
    }

    // MARK: - Uniform Text Overlay (읽기 전용 — 입력은 마킹 탭에서)

    @ViewBuilder
    private func uniformTextOverlay(frame: Frame) -> some View {
        let numberOffsetY = frame.numberOffsetY ?? -20
        let nameOffsetY = frame.nameOffsetY ?? 40

        // 이름 폰트 자동 축소 (글자 수에 따라)
        let nameSize: CGFloat = {
            let count = viewModel.playerNameText.count
            let base = viewModel.nameFontSize
            if count <= 4 { return base }
            else if count <= 6 { return base * 0.85 }
            else if count <= 8 { return base * 0.72 }
            else { return base * 0.62 }
        }()

        VStack(spacing: 0) {
            // 등번호 표시 (OutlineText + 커스텀 폰트)
            if true {
                let displayNumber = viewModel.numberText.isEmpty ? "00" : viewModel.numberText
                OutlineText(
                    text: displayNumber,
                    outlineColor: viewModel.numberOutlineColor,
                    outlineWidth: 5.4
                )
                .typography(.bmdohyeon75)
                .foregroundStyle(viewModel.numberInnerColor)
            }
        }
        .offset(y: numberOffsetY)

        // 이름 표시 (곡률에 따라 직선 or 곡선)
        if true {
            let displayName = viewModel.playerNameText.isEmpty ? "텍스트" : viewModel.playerNameText
            let normalized = (viewModel.textCurvature - 0.16) / (0.84 - 0.16)

            // 중간 이상 곡률에서 이름을 위로 올려 등번호와 겹침 방지
            let nameUpshift: CGFloat = max(normalized - 0.3, 0) / 0.7 * 14.0
            let adjustedNameOffsetY = nameOffsetY - nameUpshift

            if normalized < 0.01 {
                // 최소 곡률: 직선 텍스트 (원래 자간)
                OutlineText(
                    text: displayName,
                    outlineColor: viewModel.nameOutlineColor,
                    outlineWidth: 3.86
                )
                .font(.custom(.esamanruMedium, size: nameSize))
                .foregroundStyle(viewModel.nameInnerColor)
                .offset(y: adjustedNameOffsetY)
            } else {
                // 곡선 텍스트 (Canvas 기반)
                curvedNameCanvas(
                    text: displayName,
                    fontSize: nameSize,
                    curvature: viewModel.textCurvature,
                    innerColor: viewModel.nameInnerColor,
                    outlineColor: viewModel.nameOutlineColor
                )
                .frame(width: 400 * previewScale, height: 150 * previewScale)
                .offset(y: adjustedNameOffsetY)
            }
        }
    }

    // MARK: - 곡선 이름 텍스트 (Canvas)

    /// CG 합성의 drawCurvedOutlinedText와 동일한 수학 — 프리뷰용 16방향 아웃라인
    @ViewBuilder
    private func curvedNameCanvas(
        text: String,
        fontSize: CGFloat,
        curvature: CGFloat,
        innerColor: Color,
        outlineColor: Color,
        outlineWidth: CGFloat = 3.86
    ) -> some View {
        let uiFont = UIFont(name: FontFamily.esamanruMedium.fontName, size: fontSize)
            ?? UIFont.systemFont(ofSize: fontSize)

        Canvas { context, size in
            let radius = 55.0 / max(curvature, 0.01)
            let centerX = size.width / 2
            let arcCenterY = size.height / 2 + radius

            let chars = Array(text)
            let charWidths = chars.map { char in
                NSAttributedString(
                    string: String(char),
                    attributes: [.font: uiFont]
                ).size().width
            }
            let totalWidth = charWidths.reduce(0, +)
            let totalAngle = totalWidth / radius
            // 곡률 정규화 (0.16 → 0, 0.84 → 1) → 자간 0에서 점진적 증가
            let normalized = (curvature - 0.16) / (0.84 - 0.16)
            let letterSpacing: CGFloat = 8.0 * normalized
            let spacedTotalWidth = totalWidth + letterSpacing * CGFloat(chars.count - 1)
            let totalAngleWithSpacing = spacedTotalWidth / radius

            var currentAngle = -CGFloat.pi / 2 - totalAngleWithSpacing / 2

            for i in 0..<chars.count {
                let charWidth = charWidths[i]
                let charAngle = charWidth / radius
                let spacedCharAngle = (charWidth + letterSpacing) / radius
                let midAngle = currentAngle + spacedCharAngle / 2

                let x = centerX + radius * cos(midAngle)
                let y = arcCenterY + radius * sin(midAngle)

                var charCtx = context
                charCtx.translateBy(x: x, y: y)
                charCtx.rotate(by: Angle(radians: midAngle + CGFloat.pi / 2))

                let charStr = String(chars[i])

                // 아웃라인 (16방향 — 프리뷰 성능 고려)
                let outlineResolved = context.resolve(
                    Text(charStr)
                        .font(.custom(.esamanruMedium, size: fontSize))
                        .foregroundStyle(outlineColor)
                )
                for d in 0..<16 {
                    let a = CGFloat(d) * (2 * .pi / 16)
                    let dx = cos(a) * outlineWidth
                    let dy = sin(a) * outlineWidth
                    charCtx.draw(outlineResolved, at: CGPoint(x: dx, y: dy))
                }

                // 내부 색상
                let fillResolved = context.resolve(
                    Text(charStr)
                        .font(.custom(.esamanruMedium, size: fontSize))
                        .foregroundStyle(innerColor)
                )
                charCtx.draw(fillResolved, at: .zero)

                currentAngle += spacedCharAngle
            }
        }
    }
}
