//
//  BundleVideoGenerator+Particle.swift
//  Keychy
//
//  Created by 길지훈 on 1/14/26.
//

import Foundation
import SpriteKit
import Lottie

// MARK: - Particle Effects (실시간 렌더링)

extension BundleVideoGenerator {

    /// 파티클 재생 정보
    /// 프리렌더링 대신 LottieAnimationView를 유지하며 매 프레임 실시간 렌더링
    struct ParticlePlaybackInfo {
        let displaySprite: SKSpriteNode
        let startedAtFrame: Int
        let particleId: String
        let lottieView: LottieAnimationView
        let animation: LottieAnimation
        let imageRenderer: UIGraphicsImageRenderer
        let totalFrames: Int
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

    /// 파티클 시작 (LottieView만 생성, 프리렌더링 없음)
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

        // 레이아웃 초기화
        lottieView.setNeedsLayout()
        lottieView.layoutIfNeeded()

        // UIGraphicsImageRenderer 1회 생성 (파티클 수명 동안 재사용)
        let imageRenderer = UIGraphicsImageRenderer(bounds: lottieView.bounds)

        // 스프라이트 생성
        let sprite = SKSpriteNode()
        sprite.size = CGSize(width: scene.size.width, height: scene.size.height)
        sprite.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        sprite.zPosition = 100
        sprite.alpha = 1.0

        scene.addChild(sprite)

        let totalFrames = Int(animation.endFrame - animation.startFrame)

        playingParticles[keyringIndex] = ParticlePlaybackInfo(
            displaySprite: sprite,
            startedAtFrame: frameIndex,
            particleId: particleId,
            lottieView: lottieView,
            animation: animation,
            imageRenderer: imageRenderer,
            totalFrames: totalFrames
        )
    }

    /// 파티클 실시간 렌더링 (매 프레임 Lottie → SKTexture 변환)
    private func updateActiveParticle(for keyringIndex: Int, at frameIndex: Int, scene: MultiKeyringScene) -> Bool {
        guard let particleInfo = playingParticles[keyringIndex] else {
            return false
        }

        let offset = frameIndex - particleInfo.startedAtFrame

        // 애니메이션 종료 체크
        if offset >= particleInfo.totalFrames {
            particleInfo.displaySprite.removeFromParent()
            return true
        }

        // Lottie 프레임 설정 + 렌더링
        let targetFrame = particleInfo.animation.startFrame + CGFloat(offset)
        particleInfo.lottieView.currentFrame = AnimationFrameTime(targetFrame)
        particleInfo.lottieView.setNeedsDisplay()
        particleInfo.lottieView.layer.displayIfNeeded()

        // Core Graphics로 이미지 캡처 → SKTexture 변환
        let image = particleInfo.imageRenderer.image { context in
            particleInfo.lottieView.layer.render(in: context.cgContext)
        }
        particleInfo.displaySprite.texture = SKTexture(image: image)

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
