//
//  LenticularFusionView+Effects.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import SwiftUI
import SpriteKit

// MARK: - 후광 (Radial Glow)

extension LenticularFusionView {

    var glowLayer: some View {
        AngularGradient(
            colors: [
                .red.opacity(0.25 * glowIntensity),
                .orange.opacity(0.2 * glowIntensity),
                .yellow.opacity(0.18 * glowIntensity),
                .green.opacity(0.18 * glowIntensity),
                .cyan.opacity(0.18 * glowIntensity),
                .blue.opacity(0.2 * glowIntensity),
                .purple.opacity(0.25 * glowIntensity),
                .red.opacity(0.25 * glowIntensity)
            ],
            center: .center
        )
        .blur(radius: 50)
        .scaleEffect(1.3)
        .rotationEffect(.degrees(glowRotation))
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - 링 펄스

extension LenticularFusionView {

    var ringPulseLayer: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                    center: .center
                ),
                lineWidth: 3
            )
            .frame(width: FusionLayout.ringPulseSize, height: FusionLayout.ringPulseSize)
            .scaleEffect(ringScale)
            .opacity(ringOpacity)
            .allowsHitTesting(false)
    }
}

// MARK: - 파티클 레이어

extension LenticularFusionView {

    var particleLayer: some View {
        ZStack {
            ForEach(particleSeeds) { seed in
                let hue = seed.angle / (2 * .pi)
                Circle()
                    .fill(Color(hue: hue, saturation: 1.0, brightness: 1.0))
                    .frame(width: seed.size, height: seed.size)
                    .shadow(color: Color(hue: hue, saturation: 0.8, brightness: 1.0), radius: 8)
                    .offset(
                        x: cos(seed.angle) * seed.distance,
                        y: sin(seed.angle) * seed.distance
                    )
                    .opacity(ringOpacity)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 썸네일 레이어 (캐릭터 등장 + 빨려들어가기)

extension LenticularFusionView {

    @ViewBuilder
    func thumbnailsLayer(
        geo: GeometryProxy,
        cardWidth: CGFloat,
        cardHeight: CGFloat
    ) -> some View {
        if phase >= .approach && phase <= .merge {
            let thumbWidth = cardWidth * FusionLayout.thumbScale
            let thumbHeight = cardHeight * FusionLayout.thumbScale

            if let imageA = viewModel.imageA {
                Image(uiImage: imageA)
                    .resizable()
                    .scaledToFill()
                    .frame(width: thumbWidth, height: thumbHeight)
                    .clipShape(RoundedRectangle(cornerRadius: FusionLayout.thumbCornerRadius))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .scaleEffect(phase == .merge ? 0.3 : aScale)
                    .rotationEffect(.degrees(aRotation))
                    .offset(x: phase == .merge ? 0 : aOffsetX,
                            y: phase == .merge ? 0 : aOffsetY)
                    .opacity(phase == .merge ? 0.0 : (aScale > 0 ? 1.0 : 0.0))
            }

            if let imageB = viewModel.imageB {
                Image(uiImage: imageB)
                    .resizable()
                    .scaledToFill()
                    .frame(width: thumbWidth, height: thumbHeight)
                    .clipShape(RoundedRectangle(cornerRadius: FusionLayout.thumbCornerRadius))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .scaleEffect(phase == .merge ? 0.3 : bScale)
                    .rotationEffect(.degrees(bRotation))
                    .offset(x: phase == .merge ? 0 : bOffsetX,
                            y: phase == .merge ? 0 : bOffsetY)
                    .opacity(phase == .merge ? 0.0 : (bScale > 0 ? 1.0 : 0.0))
            }
        }
    }
}

// MARK: - 플래시 레이어

extension LenticularFusionView {

    var flashLayer: some View {
        Color.black
            .ignoresSafeArea()
            .opacity(phase == .flash ? 1.0 : 0.0)
    }
}

// MARK: - 카드 등장 레이어

extension LenticularFusionView {

    @ViewBuilder
    func cardRevealLayer(cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        if phase >= .reveal {
            Group {
                if let scene = previewScene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .frame(width: cardWidth, height: cardHeight)
                }
            }
            .rotation3DEffect(
                .degrees(Double(LenticularMotionManager.shared.signedTilt) * FusionLayout.tiltMultiplier),
                axis: (x: 0, y: 1, z: 0),
                perspective: FusionLayout.tiltPerspective
            )
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: LenticularMotionManager.shared.signedTilt)
            .shadow(color: .black.opacity(0.15), radius: 20)
        }
    }
}

// MARK: - 힌트 텍스트

extension LenticularFusionView {

    @ViewBuilder
    func hintTextLayer(cardHeight: CGFloat) -> some View {
        if phase == .settled {
            Text("기기를 좌우로 기울여보세요")
                .font(.subheadline)
                .fontWeight(.medium)
                .tracking(3)
                .foregroundStyle(.black.opacity(0.6))
                .mask {
                    GeometryReader { geo in
                        ZStack {
                            Color.white.opacity(0.3)

                            LinearGradient(
                                colors: [.clear, .white, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geo.size.width * 0.5)
                            .offset(x: geo.size.width * shimmerPhase)
                        }
                    }
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        shimmerPhase = 1.5
                    }
                }
                .transition(.opacity)
                .offset(y: (cardHeight / 2) + FusionLayout.hintBottomPadding)
        }
    }
}

// MARK: - 커스텀 네비게이션

extension LenticularFusionView {

    var customToolbar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                cleanupScene()
                viewModel.bodyImage = nil
                router.pop()
            }
        } center: {
            EmptyView()
        } trailing: {
            NextToolbarButton {
                router.push(.lenticularCustomizing)
            }
        }
        .opacity(showToolbar ? 1.0 : 0.0)
    }
}
