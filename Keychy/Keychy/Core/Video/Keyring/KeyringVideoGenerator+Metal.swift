//
//  KeyringVideoGenerator+Metal.swift
//  Keychy
//
//  Created by 길지훈 on 1/12/26.
//

import Foundation
import AVFoundation
import Metal
import MetalKit
import CoreVideo

// MARK: - Metal Utilities

extension KeyringVideoGenerator {

    /// PixelBufferPool에서 재사용 가능한 CVPixelBuffer 획득
    /// - 매 프레임마다 새로 할당하지 않고, AVAssetWriter의 풀에서 꺼내 재활용
    /// - 풀이 아직 준비되지 않은 경우에만 직접 생성 (fallback)
    func createPixelBuffer() -> CVPixelBuffer? {
        // pixelBufferPool이 있으면 재활용 (메모리 효율)
        if let pool = pixelBufferAdaptor?.pixelBufferPool {
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
            if status == kCVReturnSuccess {
                return pixelBuffer
            }
        }

        // fallback: 풀이 없으면 직접 생성
        let attrs = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess else {
            return nil
        }

        return pixelBuffer
    }

    /// Metal RenderPassDescriptor 생성
    /// - 저장된 textureCache를 재사용하여 CVPixelBuffer → MTLTexture 변환
    func createRenderPassDescriptor(for pixelBuffer: CVPixelBuffer) -> MTLRenderPassDescriptor {
        guard let textureCache = textureCache else {
            fatalError("Metal texture cache not available")
        }

        // 캐시 내부의 오래된 텍스처 참조 정리
        CVMetalTextureCacheFlush(textureCache, 0)

        var textureRef: CVMetalTexture?

        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &textureRef
        )

        guard let texture = textureRef.flatMap({ CVMetalTextureGetTexture($0) }) else {
            fatalError("Failed to create texture from pixel buffer")
        }

        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        descriptor.colorAttachments[0].storeAction = .store

        return descriptor
    }
}
