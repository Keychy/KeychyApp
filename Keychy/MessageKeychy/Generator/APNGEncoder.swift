//
//  APNGEncoder.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-22.
//

import UIKit
import ImageIO
import UniformTypeIdentifiers

/// ImageIO 기반 APNG 인코더
///
/// `CGImageDestination`에 프레임 수를 2 이상으로 지정하면
/// 자동으로 APNG 포맷으로 인코딩된다.
/// `kCGImagePropertyAPNG*` 키로 루프 횟수와 딜레이를 제어한다.
enum APNGEncoder {

    /// UIImage 배열을 APNG Data로 인코딩
    /// - Parameters:
    ///   - frames: 인코딩할 UIImage 배열
    ///   - delayTime: 프레임 간 딜레이 (초 단위)
    ///   - loopCount: 반복 횟수 (0 = 무한)
    /// - Returns: APNG Data (실패 시 nil)
    static func encode(
        frames: [UIImage],
        delayTime: Double = 0.1,
        loopCount: Int = 0
    ) -> Data? {
        guard !frames.isEmpty else { return nil }

        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            frames.count,
            nil
        ) else { return nil }

        let frameProperties: [CFString: Any] = [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyAPNGDelayTime: delayTime
            ]
        ]

        for (index, frame) in frames.enumerated() {
            guard let cgImage = frame.cgImage else { return nil }

            if index == 0 {
                // 첫 프레임에 루프 카운트 설정
                let firstFrameProperties: [CFString: Any] = [
                    kCGImagePropertyPNGDictionary: [
                        kCGImagePropertyAPNGLoopCount: loopCount,
                        kCGImagePropertyAPNGDelayTime: delayTime
                    ]
                ]
                CGImageDestinationAddImage(destination, cgImage, firstFrameProperties as CFDictionary)
            } else {
                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
            }
        }

        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
