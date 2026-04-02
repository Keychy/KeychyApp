//
//  LenticularFusionView.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import SwiftUI
import SpriteKit

// MARK: - 상수 (FusionView 전용)

enum FusionLayout {
    static let cardWidthRatio: CGFloat = 0.75
    static let cardAspectRatio: CGFloat = 300.0 / 245.0
    static let thumbScale: CGFloat = 0.38
    static let cardCornerRadius: CGFloat = 16
    static let thumbCornerRadius: CGFloat = 12
    static let tiltMultiplier: Double = KeyringScale.lenticularTiltMultiplier
    static let tiltPerspective: CGFloat = KeyringScale.lenticularTiltPerspective
    static let ringPulseSize: CGFloat = 300
    static let particleCount = 12
    static let hintBottomPadding: CGFloat = 30
}

// MARK: - 햅틱

enum FusionHaptic {
    static let light = UIImpactFeedbackGenerator(style: .light)
    static let medium = UIImpactFeedbackGenerator(style: .medium)
    static let heavy = UIImpactFeedbackGenerator(style: .heavy)

    static func prepareAll() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }
}

// MARK: - LenticularFusionView

struct LenticularFusionView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: LenticularVM

    // MARK: - 애니메이션 상태
    @State var phase: AnimationPhase = .ready
    @State var showToolbar = false

    // MARK: - SpriteKit Scene 캐싱
    @State var previewScene: SKScene?

    // MARK: - 이미지 A 상태
    @State var aOffsetX: CGFloat = -500
    @State var aOffsetY: CGFloat = 0
    @State var aScale: CGFloat = 0.0
    @State var aRotation: Double = 0

    // MARK: - 이미지 B 상태
    @State var bOffsetX: CGFloat = 500
    @State var bOffsetY: CGFloat = 0
    @State var bScale: CGFloat = 0.0
    @State var bRotation: Double = 0

    // MARK: - 효과 상태
    @State var glowIntensity: CGFloat = 0.0
    @State var glowRotation: Double = 0.0
    @State var ringScale: CGFloat = 0.0
    @State var ringOpacity: CGFloat = 0.0
    @State var particleSeeds: [ParticleSeed] = []

    // MARK: - 렌티큘러 햅틱
    @State var lenticularHaptic: LenticularHapticManager?

    // MARK: - 쉬머 (힌트 텍스트)
    @State var shimmerPhase: CGFloat = -0.5

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * FusionLayout.cardWidthRatio
            let cardHeight = cardWidth * FusionLayout.cardAspectRatio

            ZStack {
                Color.white.ignoresSafeArea()

                glowLayer

                thumbnailsLayer(geo: geo, cardWidth: cardWidth, cardHeight: cardHeight)

                particleLayer

                ringPulseLayer

                flashLayer

                cardRevealLayer(cardWidth: cardWidth, cardHeight: cardHeight)

                hintTextLayer(cardHeight: cardHeight)

                customToolbar
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task { await playAnimation() }
        .onDisappear { cleanupScene() }
    }
}

// MARK: - 애니메이션 Phase

extension LenticularFusionView {

    enum AnimationPhase: Int, Comparable {
        case ready = 0
        case approach
        case merge
        case flash
        case reveal
        case settled

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - 파티클 모델

extension LenticularFusionView {

    struct ParticleSeed: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
    }
}
