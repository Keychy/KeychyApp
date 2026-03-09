//
//  BundleVideoGenerator+Setup.swift
//  Keychy
//
//  Created by 길지훈 on 1/14/26.
//

import Foundation
import SpriteKit
import AVFoundation
import Lottie

// MARK: - Setup

extension BundleVideoGenerator {

    /// MultiKeyringScene 생성
    func createScene(
        keyringDataList: [MultiKeyringScene.KeyringData],
        backgroundImageURL: String?,
        backgroundLottieId: String? = nil,
        carabinerBackImageURL: String?,
        carabinerFrontImageURL: String?,
        carabinerLottieId: String? = nil,
        carabinerX: CGFloat,
        carabinerY: CGFloat,
        carabinerWidth: CGFloat,
        carabinerType: CarabinerType?,
        setupComplete: @escaping () -> Void
    ) -> MultiKeyringScene {
        let sceneWidth = CGFloat(width) / bundleScale
        let sceneHeight = CGFloat(height) / bundleScale

        let offsetX: CGFloat = 15
        let offsetY: CGFloat = -30
        let adjustedKeyringDataList = keyringDataList.map { data in
            MultiKeyringScene.KeyringData(
                index: data.index,
                position: CGPoint(
                    x: data.position.x + offsetX,
                    y: data.position.y + offsetY
                ),
                bodyImageURL: data.bodyImageURL,
                templateId: data.templateId,
                soundId: data.soundId,
                customSoundURL: data.customSoundURL,
                particleId: data.particleId,
                hookOffsetY: data.hookOffsetY,
                chainLength: data.chainLength
            )
        }

        let scene = MultiKeyringScene(
            keyringDataList: adjustedKeyringDataList,
            ringType: .basic,
            chainType: .basic,
            backgroundColor: .clear,
            backgroundImageURL: backgroundImageURL,
            carabinerBackImageURL: carabinerBackImageURL,
            carabinerFrontImageURL: carabinerFrontImageURL,
            carabinerX: carabinerX + offsetX,
            carabinerY: carabinerY + offsetY,
            carabinerWidth: carabinerWidth,
            carabinerLottieId: carabinerLottieId
        )
        scene.currentCarabinerType = carabinerType
        scene.scaleMode = .aspectFill
        scene.size = CGSize(width: sceneWidth, height: sceneHeight)
        scene.disableShadows = true  // 영상 생성 시 그림자 비활성화 (성능 최적화)

        if let bgLottieId = backgroundLottieId,
           let animation = LottieItemManager.shared.loadBackgroundAnimation(id: bgLottieId) {
            // Lottie 배경: 첫 프레임만 정적 렌더링 (메모리 절약)
            let config = LottieConfiguration(renderingEngine: .mainThread)
            let lottieView = LottieAnimationView(animation: animation, configuration: config)
            lottieView.frame = CGRect(origin: .zero, size: CGSize(width: sceneWidth, height: sceneHeight))
            lottieView.contentMode = .scaleAspectFill
            lottieView.currentFrame = AnimationFrameTime(animation.startFrame)
            lottieView.setNeedsDisplay()
            lottieView.layer.displayIfNeeded()

            let renderer = UIGraphicsImageRenderer(bounds: lottieView.bounds)
            let image = renderer.image { context in
                lottieView.layer.render(in: context.cgContext)
            }

            let backgroundNode = SKSpriteNode(texture: SKTexture(image: image))
            backgroundNode.size = CGSize(width: sceneWidth, height: sceneHeight)
            backgroundNode.position = CGPoint(x: sceneWidth / 2, y: sceneHeight / 2)
            backgroundNode.zPosition = -1000
            scene.addChild(backgroundNode)
        } else if let bgImage = backgroundImage {
            // 정적 이미지 배경 (기존)
            let backgroundNode = SKSpriteNode(texture: SKTexture(image: bgImage))
            backgroundNode.size = CGSize(width: sceneWidth, height: sceneHeight)
            backgroundNode.position = CGPoint(x: sceneWidth / 2, y: sceneHeight / 2)
            backgroundNode.zPosition = -1000
            scene.addChild(backgroundNode)
        }

        if let watermarkImage = UIImage(named: "shareWaterMark") {
            let watermarkNode = SKSpriteNode(texture: SKTexture(image: watermarkImage))
            
            let nodeWidth: CGFloat = 100
            let nodeHeight: CGFloat = 26
            watermarkNode.size = CGSize(width: nodeWidth, height: nodeHeight)
            
            let bottomMargin = (16 + nodeHeight / 2)
            watermarkNode.position = CGPoint(x: sceneWidth / 2, y: bottomMargin)
            watermarkNode.zPosition = 999
            scene.addChild(watermarkNode)
        }
        
        scene.onSetupComplete = {
            setupComplete()
        }

        return scene
    }

    /// AVAssetWriter 설정
    func setupVideoWriter() throws {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bundle_video_\(UUID()).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoMaxKeyFrameIntervalKey: fps
            ]
        ]

        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        input.expectsMediaDataInRealTime = false

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        self.videoWriter = writer
        self.writerInput = input
        self.pixelBufferAdaptor = adaptor
    }

    /// 비디오 완성
    func finishWriting() async throws -> URL {
        writerInput?.markAsFinished()

        guard let videoWriter = videoWriter else {
            throw VideoError.saveFailed
        }

        await videoWriter.finishWriting()

        guard videoWriter.status == .completed else {
            throw VideoError.saveFailed
        }

        return videoWriter.outputURL
    }
}
