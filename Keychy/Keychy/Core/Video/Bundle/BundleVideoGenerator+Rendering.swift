//
//  BundleVideoGenerator+Rendering.swift
//  Keychy
//
//  Created by 길지훈 on 1/14/26.
//

import Foundation
import AVFoundation
import CoreMedia
import SpriteKit

// MARK: - Rendering

extension BundleVideoGenerator {

    /// 프레임 렌더링
    func renderFrames() async throws {
        guard let scene = scene,
              let renderer = renderer,
              let commandQueue = commandQueue,
              let adaptor = pixelBufferAdaptor,
              let writerInput = writerInput else {
            throw VideoError.setupFailed
        }

        for frameIndex in 0..<targetFrames {
            let currentTime = Double(frameIndex) / Double(fps)

            triggerSwipeEvents(at: frameIndex, scene: scene)
            updateParticleTextures(at: frameIndex, scene: scene, keyringDataList: keyringDataList)
            updateBackgroundLottieTexture(at: frameIndex)
            scene.updateCarabinerLottieTexture(at: frameIndex, videoFPS: Double(fps))
            scene.update(currentTime)

            // 렌티큘러: scene.update()가 모션 매니저(값 0)로 덮어쓴 뒤,
            // 시간 기반 사인파로 tilt/rotation 오버라이드
            updateLenticularTilt(at: currentTime, scene: scene)

            guard let pixelBuffer = createPixelBuffer() else {
                throw VideoError.renderFailed
            }

            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                throw VideoError.renderFailed
            }

            renderer.render(
                withViewport: CGRect(x: 0, y: 0, width: width, height: height),
                commandBuffer: commandBuffer,
                renderPassDescriptor: createRenderPassDescriptor(for: pixelBuffer)
            )

            commandBuffer.commit()
            await commandBuffer.completed()

            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(for: .seconds(0.01))
            }

            let presentationTime = CMTime(
                value: CMTimeValue(frameIndex),
                timescale: CMTimeScale(fps)
            )

            guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                throw VideoError.renderFailed
            }

            // 물리 엔진에 시뮬레이션 계산 시간 확보
            try await Task.sleep(for: .seconds(0.0167))
        }
    }

    // MARK: - 영상용 렌티큘러 tilt 애니메이션

    /// 시간 기반 사인파로 렌티큘러 셰이더 + 3D 회전을 애니메이션
    /// MultiKeyringScene 내 모든 렌티큘러 키링에 적용
    private func updateLenticularTilt(at time: Double, scene: MultiKeyringScene) {
        let gyroscopeData = keyringDataList.filter { $0.isGyroscope }
        guard !gyroscopeData.isEmpty else { return }

        // 사인파: 5초 동안 1회 왕복 (-1 → +1 → -1)
        let signedTilt = sin(time * .pi * 2.0 / duration)
        let tilt = abs(signedTilt)

        // X축은 약간 다른 주기로 자연스러운 움직임
        let signedPitch = sin(time * .pi * 1.5 / duration)

        for data in gyroscopeData {
            if let body = scene.bodyNodes[data.index],
               let transform = body.childNode(withName: "lenticularTransform") as? SKTransformNode {
                // Y축 3D 회전 (좌우)
                transform.yRotation = CGFloat(signedTilt) * KeyringScale.lenticularYRotationMax
                // X축 3D 회전 (앞뒤)
                transform.xRotation = CGFloat(signedPitch) * KeyringScale.lenticularXRotationMax

                // 셰이더 u_tilt 업데이트 → A↔B 전환
                if let visual = transform.childNode(withName: "lenticularVisual") as? SKSpriteNode,
                   let shader = visual.shader {
                    shader.uniformNamed("u_tilt")?.floatValue = Float(tilt)
                }
            }
        }
    }

    /// 배경 Lottie 텍스처 수동 업데이트
    private func updateBackgroundLottieTexture(at frameIndex: Int) {
        guard let textures = backgroundLottieTextures,
              !textures.isEmpty,
              let node = backgroundLottieNode else { return }

        let lottieFrameIndex = Int(Double(frameIndex) * backgroundLottieFPS / Double(fps)) % textures.count
        node.texture = textures[lottieFrameIndex]
    }

    /// 스와이프 이벤트 트리거
    private func triggerSwipeEvents(at frameIndex: Int, scene: MultiKeyringScene) {
        for (eventIndex, eventFrame) in swipeEventFrames.enumerated() {
            if frameIndex == eventFrame {
                let keyringIndex = swipeOrder[eventIndex]
                let velocity = swipeVelocities[eventIndex]
                let direction: CGFloat = keyringIndex == 2 ? -1 : 1
                let swipeVector = CGVector(dx: velocity * direction, dy: 0)

                scene.applySwipeForceToKeyring(index: keyringIndex, velocity: swipeVector)
            }
        }
    }
}
