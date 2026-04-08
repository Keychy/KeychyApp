//
//  KeyringVideoGenerator+Setup.swift
//  Keychy
//
//  Created by 길지훈 on 1/12/26.
//

import Foundation
import SpriteKit
import AVFoundation

// MARK: - Setup

extension KeyringVideoGenerator {

    /// KeyringScene 생성
    /// Scene 크기를 keyringScale로 나눠서 작게 만들고, Viewport에 렌더링하면 자동 확대
    func createScene<VM: KeyringViewModelProtocol>(
        viewModel: VM,
        setupComplete: @escaping () -> Void
    ) -> KeyringScene {
        let sceneWidth = CGFloat(width) / keyringScale
        let sceneHeight = CGFloat(height) / keyringScale

        let scene = KeyringScene(
            ringType: .basic,
            chainType: .basic,
            templateId: viewModel.templateId,
            isGyroscope: viewModel.isGyroscope,
            screen: .video,
            bodyImage: viewModel.bodyImage,
            backgroundColor: .clear,
            hookOffsetY: viewModel.hookOffsetY != 0 ? viewModel.hookOffsetY : nil,
            chainLength: viewModel.chainLength
        )
        scene.scaleMode = .aspectFill
        scene.size = CGSize(width: sceneWidth, height: sceneHeight)

        // 배경 이미지 추가 (scene보다 여유 있게 배치)
        if let bgImage = backgroundImage {
            let backgroundNode = SKSpriteNode(texture: SKTexture(image: bgImage))
            backgroundNode.size = CGSize(width: sceneWidth * 1.25, height: sceneHeight * 1.25)
            backgroundNode.position = CGPoint(x: sceneWidth / 2, y: sceneHeight / 2)
            backgroundNode.zPosition = -1000
            scene.addChild(backgroundNode)
        }

        // Setup 완료 콜백 설정 (bind 전에 설정해야 bind가 이 콜백을 래핑하여
        // 렌티큘러 스타일 초기값을 적용할 수 있음)
        scene.onSetupComplete = {
            setupComplete()
        }

        // VM 바인딩 (onSetupComplete 래핑 + 렌티큘러 스타일 초기 적용)
        scene.bind(to: viewModel)

        return scene
    }

    /// AVAssetWriter 설정
    /// H.264 코덱으로 1080x1920 비디오 인코딩
    func setupVideoWriter() throws {
        // 파일 이름에 사용 불가 문자 제거
        let safeName = keyringName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName)_\(UUID().uuidString.prefix(8)).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        // 비디오 설정
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        input.expectsMediaDataInRealTime = false

        // PixelBuffer 설정
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

    /// 비디오 작성 완료 및 URL 반환
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
