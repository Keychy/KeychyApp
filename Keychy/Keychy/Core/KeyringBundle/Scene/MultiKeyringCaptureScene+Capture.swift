//
//  MultiKeyringCaptureScene+Capture.swift
//  Keychy
//
//  Created by Rundo on 11/10/25.
//

import Foundation
import SpriteKit
import SwiftUI
import UIKit

extension MultiKeyringCaptureScene {

    // MARK: - Instance Methods

    /// Scene을 PNG 이미지로 캡처
    @MainActor
    func captureToPNG() async -> Data? {
        // 캡처용 SKView 생성
        let view = SKView(frame: CGRect(origin: .zero, size: self.size))

        // 투명도 설정 (PNG 알파 채널 보존)
        view.allowsTransparency = true
        view.backgroundColor = .clear

        view.presentScene(self)

        // SpriteKit 렌더링 대기
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

        // 텍스처 캡처
        guard let texture = view.texture(from: self) else {
            return nil
        }

        // CGImage 변환
        let cgImage = texture.cgImage()

        // UIImage로 변환 후 PNG 데이터 추출
        let image = UIImage(cgImage: cgImage)
        guard let pngData = image.pngData() else {
            return nil
        }

        return pngData
    }

    // MARK: - Static Helper Methods

    /// 번들 이미지 캡처
    /// - Parameters:
    ///   - keyringDataList: 키링 데이터 리스트
    ///   - backgroundImageURL: 배경 이미지 URL (nil이면 배경 없이 캡처)
    ///   - carabinerBackImageURL: 카라비너 뒷면 이미지 URL (hamburger 타입)
    ///   - carabinerFrontImageURL: 카라비너 앞면 이미지 URL (hamburger 타입)
    ///   - carabinerType: 카라비너 타입
    ///   - carabinerX: 카라비너 왼쪽 상단 X 좌표
    ///   - carabinerY: 카라비너 왼쪽 상단 Y 좌표
    ///   - carabinerWidth: 카라비너 너비
    ///   - trimTransparentEdges: 투명 여백 제거 여부 (위젯용)
    ///   - customCaptureSize: 커스텀 캡처 사이즈 (nil이면 기본값 사용)
    /// - Returns: 캡처된 PNG 데이터
    static func captureBundleImage(
        keyringDataList: [MultiKeyringCaptureScene.KeyringData],
        backgroundImageURL: String? = nil,
        carabinerBackImageURL: String? = nil,
        carabinerFrontImageURL: String? = nil,
        carabinerType: CarabinerType? = nil,
        carabinerX: CGFloat = 0,
        carabinerY: CGFloat = 0,
        carabinerWidth: CGFloat = 0,
        trimTransparentEdges: Bool = false,
        customCaptureSize: CGSize? = nil
    ) async -> Data? {
        do {
            try await preloadAllImages(
                keyringDataList: keyringDataList,
                backgroundURL: backgroundImageURL,
                carabinerBackURL: carabinerBackImageURL,
                carabinerFrontURL: carabinerFrontImageURL,
                carabinerType: carabinerType
            )
        } catch {
            return nil
        }

        // 캡처 사이즈 (커스텀 또는 기본값)
        let captureSize = customCaptureSize ?? CGSize(width: 402, height: 874)


        return await withCheckedContinuation { continuation in
            var loadingCompleted = false

            // MultiKeyringCaptureScene 생성 (캡처 전용, 물리 없음)
            let scene = MultiKeyringCaptureScene(
                keyringDataList: keyringDataList,
                carabinerType: carabinerType,
                ringType: .basic,
                chainType: .basic,
                backgroundColor: .clear,
                backgroundImageURL: backgroundImageURL,
                carabinerBackImageURL: carabinerBackImageURL,
                carabinerFrontImageURL: carabinerFrontImageURL,
                carabinerX: carabinerX,
                carabinerY: carabinerY,
                carabinerWidth: carabinerWidth,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.size = captureSize
            scene.scaleMode = .aspectFill

            // SKView 생성 및 씬 표시
            let view = SKView(frame: CGRect(origin: .zero, size: captureSize))
            view.allowsTransparency = true
            view.presentScene(scene)

            // 로딩 완료 대기
            Task {
                var waitTime = 0.0
                let checkInterval = 0.1
                let maxWaitTime = 3.0

                while !loadingCompleted && waitTime < maxWaitTime {
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                    waitTime += checkInterval
                }

                if !loadingCompleted {
                } else {
                    // 로딩 완료 후 추가 렌더링 대기
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // PNG 캡처
                var pngData = await scene.captureToPNG()

                // 투명 여백 제거 (위젯용)
                if trimTransparentEdges, let data = pngData {
                    pngData = trimTransparentEdgesFromPNG(data)
                }

                continuation.resume(returning: pngData)
            }
        }
    }

    // MARK: - Image Trimming

    /// PNG 이미지에서 투명 여백 제거
    private static func trimTransparentEdgesFromPNG(_ pngData: Data) -> Data? {
        guard let uiImage = UIImage(data: pngData),
              let cgImage = uiImage.cgImage else {
            return pngData
        }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return pngData
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            return pngData
        }

        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)

        // 불투명 영역 경계 찾기
        var minX = width, minY = height, maxX = 0, maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let alpha = data[offset + 3]

                if alpha > 0 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        // 유효한 영역이 없으면 원본 반환
        guard minX < maxX && minY < maxY else {
            return pngData
        }

        // 약간의 패딩 추가 (10px)
        let padding = 10
        minX = max(0, minX - padding)
        minY = max(0, minY - padding)
        maxX = min(width - 1, maxX + padding)
        maxY = min(height - 1, maxY + padding)

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return pngData
        }

        let croppedImage = UIImage(cgImage: croppedCGImage)

        // 위젯에 적합한 크기로 리사이즈 (최대 500px)
        let maxSize: CGFloat = 500
        let croppedWidth = croppedImage.size.width
        let croppedHeight = croppedImage.size.height

        if croppedWidth <= maxSize && croppedHeight <= maxSize {
            return croppedImage.pngData() ?? pngData
        }

        let scale = min(maxSize / croppedWidth, maxSize / croppedHeight)
        let newSize = CGSize(width: croppedWidth * scale, height: croppedHeight * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        croppedImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage?.pngData() ?? croppedImage.pngData() ?? pngData
    }
    
    // MARK: - Image Preloading (Cache Warming)
    
    /// 모든 이미지를 사전에 로드하여 StorageManager 캐시에 저장
    /// - 캡쳐 전에 호출하여 Scene 내부에서의 이미지 로딩 실패를 방지
    private static func preloadAllImages(
        keyringDataList: [MultiKeyringCaptureScene.KeyringData],
        backgroundURL: String?,
        carabinerBackURL: String?,
        carabinerFrontURL: String?,
        carabinerType: CarabinerType?
    ) async throws {
        // 1. 배경 이미지 로드 (있는 경우에만)
        if let bgURL = backgroundURL {
            _ = try await StorageManager.shared.getImage(path: bgURL)
        }
        
        // 2. 모든 키링 bodyImage 병렬 로드
        try await withThrowingTaskGroup(of: Void.self) { group in
            for keyringData in keyringDataList {
                group.addTask {
                    _ = try await StorageManager.shared.getImage(path: keyringData.bodyImageURL)
                }
            }
            try await group.waitForAll()
        }
        
        // 3. 카라비너 이미지 로드
        if carabinerType == .hamburger {
            // 카라비너 뒷 이미지 없으면 패스
            if carabinerBackURL != "none" {
                if let backURL = carabinerBackURL {
                    _ = try await StorageManager.shared.getImage(path: backURL)
                }
            }
            if let frontURL = carabinerFrontURL {
                _ = try await StorageManager.shared.getImage(path: frontURL)
            }
        } else if carabinerType == .plain {
            if let backURL = carabinerBackURL {
                _ = try await StorageManager.shared.getImage(path: backURL)
            }
        }
        
        // 4. 캐시 동기화 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
    }
}
