//
//  BundleVideoGenerator+Particle.swift
//  Keychy
//
//  Created by 길지훈 on 1/14/26.
//

import Foundation
import SpriteKit
import Lottie

// MARK: - Particle Effects

extension BundleVideoGenerator {

    /// 파티클 재생 정보
    /// 시작 시점에 모든 프레임을 프리렌더링하여 재생 중에는 캐시된 텍스처만 사용
    struct ParticlePlaybackInfo {
        let displaySprite: SKSpriteNode     // 화면에 표시되는 스프라이트
        let startedAtFrame: Int             // 파티클 시작 프레임
        let particleId: String              // 파티클 ID
        let preRenderedTextures: [SKTexture] // 프리렌더링된 텍스처 배열
    }

    /// 파티클 업데이트
    func updateParticleTextures(at frameIndex: Int, scene: MultiKeyringScene, keyringDataList: [MultiKeyringScene.KeyringData]) {
        for (eventIndex, eventFrame) in swipeEventFrames.enumerated() {
            if frameIndex == eventFrame {
                let keyringIndex = swipeOrder[eventIndex]
                guard let keyringData = keyringDataList.first(where: { $0.index == keyringIndex }),
                      keyringData.particleId != "none" else {
                    continue
                }
                startParticle(for: keyringIndex, particleId: keyringData.particleId, at: frameIndex, scene: scene)
            }
        }

        let particleIndicesToRemove = playingParticles.keys.filter { keyringIndex in
            updateActiveParticle(for: keyringIndex, at: frameIndex, scene: scene)
        }

        particleIndicesToRemove.forEach { playingParticles.removeValue(forKey: $0) }
    }

    /// 파티클 시작 (모든 프레임을 프리렌더링)
    private func startParticle(for keyringIndex: Int, particleId: String, at frameIndex: Int, scene: MultiKeyringScene) {
        guard let animation = findParticleAnimation(particleId: particleId) else {
            return
        }

        // Lottie 뷰 설정
        let config = LottieConfiguration(renderingEngine: .mainThread)
        let lottieView = LottieAnimationView(animation: animation, configuration: config)
        lottieView.frame = CGRect(origin: .zero, size: CGSize(width: scene.size.width, height: scene.size.height))
        lottieView.contentMode = .scaleAspectFit
        lottieView.backgroundBehavior = .pauseAndRestore

        // 모든 프레임을 프리렌더링
        let textures = preRenderAllFrames(lottieView: lottieView, animation: animation)

        // 스프라이트 생성
        let sprite = SKSpriteNode()
        sprite.size = CGSize(width: scene.size.width, height: scene.size.height)
        sprite.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        sprite.zPosition = 100
        sprite.alpha = 1.0

        // 첫 프레임 텍스처 설정
        if let firstTexture = textures.first {
            sprite.texture = firstTexture
        }

        scene.addChild(sprite)

        playingParticles[keyringIndex] = ParticlePlaybackInfo(
            displaySprite: sprite,
            startedAtFrame: frameIndex,
            particleId: particleId,
            preRenderedTextures: textures
        )
    }

    /// Lottie 애니메이션의 모든 프레임을 SKTexture로 프리렌더링
    private func preRenderAllFrames(lottieView: LottieAnimationView, animation: LottieAnimation) -> [SKTexture] {
        let totalFrames = Int(animation.endFrame - animation.startFrame)
        var textures: [SKTexture] = []
        textures.reserveCapacity(totalFrames)

        // UIGraphicsImageRenderer를 한 번만 생성 (재사용)
        let imageRenderer = UIGraphicsImageRenderer(bounds: lottieView.bounds)

        for frameOffset in 0..<totalFrames {
            let targetFrame = animation.startFrame + CGFloat(frameOffset)
            lottieView.currentFrame = AnimationFrameTime(targetFrame)
            lottieView.setNeedsDisplay()
            lottieView.layer.displayIfNeeded()

            let image = imageRenderer.image { context in
                lottieView.layer.render(in: context.cgContext)
            }
            textures.append(SKTexture(image: image))
        }

        return textures
    }

    /// 파티클 렌더링 (프리렌더링된 텍스처 사용)
    private func updateActiveParticle(for keyringIndex: Int, at frameIndex: Int, scene: MultiKeyringScene) -> Bool {
        guard let particleInfo = playingParticles[keyringIndex] else {
            return false
        }

        let sprite = particleInfo.displaySprite
        let offset = frameIndex - particleInfo.startedAtFrame

        // 애니메이션 종료 체크
        if offset >= particleInfo.preRenderedTextures.count {
            sprite.removeFromParent()
            return true
        }

        // 프리렌더링된 텍스처 사용 (매우 빠름)
        sprite.texture = particleInfo.preRenderedTextures[offset]

        return false
    }

    /// 파티클 애니메이션 찾기
    private func findParticleAnimation(particleId: String) -> LottieAnimation? {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

        guard FileManager.default.fileExists(atPath: cachedURL.path) else {
            return nil
        }

        return LottieAnimation.filepath(cachedURL.path)
    }
}
