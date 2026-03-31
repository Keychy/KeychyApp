//
//  KeyringVideoGenerator+Rendering.swift
//  Keychy
//
//  Created by 길지훈 on 1/12/26.
//

import Foundation
import AVFoundation
import CoreMedia
import SpriteKit

// MARK: - Rendering

extension KeyringVideoGenerator {

    /// 프레임별 렌더링 수행
    /// Scene을 업데이트하고 GPU로 렌더링하여 비디오에 추가
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

            triggerSoundEvents(at: frameIndex, scene: scene)
            updateParticleTexture(at: frameIndex, scene: scene)
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

            try await Task.sleep(for: .seconds(0.0167))
        }
    }

    // MARK: - 영상용 렌티큘러 tilt 애니메이션

    /// 시간 기반 사인파로 렌티큘러 셰이더 + 3D 회전을 애니메이션
    /// - scene.update()가 모션 매니저 값(0)을 먼저 쓰므로, 이후에 호출하여 오버라이드
    /// - 5초 영상 동안 좌→우→좌 1회 왕복
    private func updateLenticularTilt(at time: Double, scene: KeyringScene) {
        guard scene.isGyroscope,
              let body = scene.bodyNode,
              let transform = body.childNode(withName: "lenticularTransform") as? SKTransformNode else { return }

        // 사인파: 5초 동안 1회 왕복 (-1 → +1 → -1)
        let signedTilt = sin(time * .pi * 2.0 / duration)
        let tilt = abs(signedTilt)

        // Y축 3D 회전 (좌우)
        transform.yRotation = CGFloat(signedTilt) * KeyringScale.lenticularYRotationMax

        // X축 3D 회전 (앞뒤, 약간 다른 주기로 자연스러운 움직임)
        let signedPitch = sin(time * .pi * 1.5 / duration)
        transform.xRotation = CGFloat(signedPitch) * KeyringScale.lenticularXRotationMax

        // 셰이더 u_tilt 업데이트 → A↔B 전환
        if let visual = transform.childNode(withName: "lenticularVisual") as? SKSpriteNode,
           let shader = visual.shader {
            shader.uniformNamed("u_tilt")?.floatValue = Float(tilt)
        }
    }
}
