//
//  LenticularFusionView+Animation.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import SwiftUI
import SpriteKit

// MARK: - 애니메이션 시퀀스

extension LenticularFusionView {

    /// sleep 래퍼 — Task cancel 시 즉시 중단
    func sleep(for seconds: Double) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }

    func playAnimation() async {
        FusionHaptic.prepareAll()

        particleSeeds = (0..<FusionLayout.particleCount).map { _ in
            ParticleSeed(
                angle: Double.random(in: 0...(2 * .pi)),
                distance: CGFloat.random(in: 80...180),
                size: CGFloat.random(in: 3...7)
            )
        }

        do {
            try await sleep(for: 0.3)

            // Phase 1: 캐릭터 등장 — A 토도도독 점프! → B 눈치보다 놀라서 점프!
            phase = .approach

            withAnimation(.easeIn(duration: 3.0)) {
                glowIntensity = 0.5
            }

            // ── A: 왼쪽에서 토도도독 걸어옴 ──

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                aScale = 0.8
                aOffsetX = -180
                aRotation = -8
            }
            try await sleep(for: 0.25)

            // 토독 1
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                aOffsetX = -130
                aOffsetY = -15
                aRotation = 5
            }
            try await sleep(for: 0.15)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                aOffsetY = 0
                aRotation = -3
            }
            try await sleep(for: 0.12)

            // 토독 2
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                aOffsetX = -80
                aOffsetY = -18
                aRotation = 6
            }
            try await sleep(for: 0.15)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                aOffsetY = 0
                aRotation = -4
            }
            try await sleep(for: 0.12)

            // 토독 3
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                aOffsetX = -40
                aOffsetY = -20
                aRotation = 7
            }
            try await sleep(for: 0.15)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                aOffsetY = 0
                aRotation = -2
            }
            try await sleep(for: 0.15)

            // A 큰 점프! → 중앙 근처로 (착지 없이 체공)
            FusionHaptic.light.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                aOffsetX = -40
                aOffsetY = -30
                aScale = 0.7
                aRotation = 15
            }
            try await sleep(for: 0.25)

            // ── B: 오른쪽에서 눈치보다 놀라서 점프! ──

            withAnimation(.easeOut(duration: 0.4)) {
                bScale = 0.7
                bOffsetX = 160
                bRotation = 5
            }
            try await sleep(for: 0.35)

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                bOffsetX = 190
                bScale = 0.65
                bRotation = 8
            }
            try await sleep(for: 0.3)

            withAnimation(.easeOut(duration: 0.3)) {
                bOffsetX = 140
                bScale = 0.75
                bRotation = 3
            }
            try await sleep(for: 0.25)

            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                bScale = 0.9
                bOffsetY = -12
                bRotation = -5
            }
            try await sleep(for: 0.15)

            // B 큰 점프! → 중앙 근처로 (착지 없이 체공)
            FusionHaptic.light.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                bOffsetX = 40
                bOffsetY = -30
                bScale = 0.7
                bRotation = -15
            }
            try await sleep(for: 0.3)

            // ── 둘 다 회전하며 빨려들어가기 ──
            FusionHaptic.medium.impactOccurred()

            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                glowRotation = 360
            }

            withAnimation(.easeIn(duration: 1.4)) {
                aRotation = 540
                bRotation = -540
            }

            withAnimation(.easeIn(duration: 0.6)) {
                aOffsetX = -20
                aOffsetY = -15
                aScale = 0.5
                bOffsetX = 20
                bOffsetY = -15
                bScale = 0.5
                glowIntensity = 0.7
            }
            try await sleep(for: 0.6)

            withAnimation(.easeIn(duration: 0.5)) {
                aOffsetX = -6
                aOffsetY = 0
                aScale = 0.25
                bOffsetX = 6
                bOffsetY = 0
                bScale = 0.25
                glowIntensity = 0.9
            }
            try await sleep(for: 0.5)

            withAnimation(.easeIn(duration: 0.3)) {
                aOffsetX = 0
                aOffsetY = 0
                aScale = 0.0
                bOffsetX = 0
                bOffsetY = 0
                bScale = 0.0
                glowIntensity = 1.0
            }
            try await sleep(for: 0.4)

            // Phase 2: merge
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .merge
            }
            try await sleep(for: 0.5)

            // Phase 3: 플래시 + 링 펄스 + 파티클
            withAnimation(.easeIn(duration: 0.15)) {
                phase = .flash
            }
            FusionHaptic.heavy.impactOccurred()

            withAnimation(.easeOut(duration: 0.8)) {
                ringScale = 3.0
                ringOpacity = 0.8
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                ringOpacity = 0.0
            }

            try await sleep(for: 0.4)

            // Scene 미리 생성
            if previewScene == nil, let bodyImage = viewModel.bodyImage {
                previewScene = buildPreviewScene(bodyImage: bodyImage)
            }

            // Phase 4: 카드 등장 + 후광 살짝 줄임
            withAnimation(.easeOut(duration: 1.5)) {
                phase = .reveal
                glowIntensity = 0.6
            }
            try await sleep(for: 1.5)

            // Phase 5: 정위치 착지
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                phase = .settled
            }
            withAnimation(.easeInOut(duration: 1.0)) {
                glowIntensity = 0.4
            }
            try await sleep(for: 0.8)

            withAnimation(.easeInOut(duration: 0.5)) {
                showToolbar = true
            }
        } catch {
            // Task cancel 시 (화면 이탈 등) 애니메이션 즉시 중단
        }
    }
}

// MARK: - Scene 빌드 & 정리

extension LenticularFusionView {

    func buildPreviewScene(bodyImage: UIImage) -> SKScene {
        let templateId = viewModel.templateId
        let sceneSize = KeyringScale.maxSize(for: templateId)
        let scene = SKScene(size: sceneSize)
        scene.backgroundColor = .clear
        // .aspectFill 필수 — Scene 비율(245:300)과 cardAspectRatio(300/245)가 일치해야 함
        // .resizeFill을 쓰면 좌표계가 변경되어 셰이더 SDF 테두리가 편향됨
        scene.scaleMode = .aspectFill

        let bodyNode = KeyringBodyComponent.createLenticularBody(
            atlasImage: bodyImage,
            templateId: templateId
        )
        bodyNode.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        bodyNode.physicsBody = nil
        scene.addChild(bodyNode)
        scene.physicsWorld.gravity = .zero

        LenticularMotionManager.shared.start()

        // 햅틱 매니저 생성 — tilt 끝점 도달 시 진동
        let haptic = LenticularHapticManager()
        lenticularHaptic = haptic

        let frameInterval: TimeInterval = 1.0 / 60.0
        let updateAction = SKAction.repeatForever(SKAction.customAction(withDuration: frameInterval) { node, _ in
            if let sprite = node as? SKSpriteNode {
                let tilt = LenticularMotionManager.shared.tilt
                sprite.shader?.uniformNamed("u_tilt")?.floatValue = Float(tilt)
                haptic.update(tilt: tilt)
            }
        })
        bodyNode.run(updateAction)

        return scene
    }

    func cleanupScene() {
        LenticularMotionManager.shared.stop()
        lenticularHaptic = nil
        previewScene?.removeAllChildren()
        previewScene?.removeAllActions()
        previewScene = nil
    }
}
