//
//  WishHorse26VM+ImageConversion.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI
import Nuke

extension WishHorse26VM {
    
    // MARK: - Horse Composition
    
    /// 선택한 프레임, 안장, 갈기를 합성하여 bodyImage로 저장
    func composeHorse() async {
        guard let frame = selectedFrame,
              let frameURL = URL(string: frame.frameURL) else {
            return
        }
        
        // 합성 시작
        await MainActor.run {
            isComposingHorse = true
        }
        
        defer {
            Task { @MainActor in
                isComposingHorse = false
            }
        }
        
        // 프레임 이미지 다운로드
        guard let frameImage = await downloadImage(from: frameURL) else {
            return
        }
        
        // 안장 이미지 다운로드 (선택된 경우)
        var saddleImage: UIImage? = nil
        if let saddle = selectedSaddle,
           let saddleURL = URL(string: saddle.imageURL) {
            saddleImage = await downloadImage(from: saddleURL)
        }
        
        // 갈기 이미지 다운로드 (선택된 경우)
        var maneImage: UIImage? = nil
        if let mane = selectedMane,
           let maneURL = URL(string: mane.imageURL) {
            maneImage = await downloadImage(from: maneURL)
        }
        
        // 프레임 크기 설정 (WishHorse26FramePreviewView와 동일)
        let targetFrameHeight: CGFloat = 310
        let frameAspect = frameImage.size.width / frameImage.size.height
        let targetFrameWidth = targetFrameHeight * frameAspect
        let targetFrameSize = CGSize(width: targetFrameWidth, height: targetFrameHeight)
        
        // type "A"인 경우 회전 및 오프셋 적용
        let shouldApplyTransform = frame.type == "A"
        
        if shouldApplyTransform {
            // type "A": 회전과 오프셋이 적용된 이미지 합성
            bodyImage = composeWithTransform(
                frameImage: frameImage,
                maneImage: maneImage,
                saddleImage: saddleImage,
                targetFrameSize: targetFrameSize
            )
        } else {
            // type "B" 또는 기타: 일반 합성
            bodyImage = composeNormal(
                frameImage: frameImage,
                maneImage: maneImage,
                saddleImage: saddleImage,
                targetFrameSize: targetFrameSize
            )
        }
    }
    
    // MARK: - Normal Composition (type "B")
    private func composeNormal(
        frameImage: UIImage,
        maneImage: UIImage?,
        saddleImage: UIImage?,
        targetFrameSize: CGSize
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetFrameSize)
        
        return renderer.image { context in
            // 1. 프레임 이미지 그리기 (배경)
            frameImage.draw(in: CGRect(origin: .zero, size: targetFrameSize))
            
            // 2. 갈기 이미지 그리기 (중간 레이어)
            if let maneImage = maneImage {
                maneImage.draw(in: CGRect(origin: .zero, size: targetFrameSize))
            }
            
            // 3. 안장 이미지 그리기 (최상위 레이어)
            if let saddleImage = saddleImage {
                saddleImage.draw(in: CGRect(origin: .zero, size: targetFrameSize))
            }
        }
    }
    
    // MARK: - Transform Composition (type "A")
    private func composeWithTransform(
        frameImage: UIImage,
        maneImage: UIImage?,
        saddleImage: UIImage?,
        targetFrameSize: CGSize
    ) -> UIImage {
        // 회전 각도 (degree -> radian)
        let rotationAngle: CGFloat = 20 * .pi / 180
        
        let xOffset: CGFloat = 29.58
        let yOffset: CGFloat = 40
        
        // 캔버스 크기: 높이를 충분히 늘림 (아래쪽 여유 공간 확보)
        let extraHeight: CGFloat = 60
        let canvasSize = CGSize(
            width: targetFrameSize.width,
            height: targetFrameSize.height + extraHeight
        )
        
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // 원본 크기의 중앙 기준점 (캔버스 위쪽에 배치)
            let centerX = targetFrameSize.width / 2 + 4
            let centerY = targetFrameSize.height / 2 + 3
            
            cgContext.translateBy(x: centerX, y: centerY)
            
            // 회전 적용
            cgContext.rotate(by: rotationAngle)
            
            // 오프셋 적용
            cgContext.translateBy(x: xOffset, y: yOffset)
            
            // 이미지들을 원본 크기 그대로 그리기
            let drawRect = CGRect(
                x: -targetFrameSize.width / 2,
                y: -targetFrameSize.height / 2,
                width: targetFrameSize.width,
                height: targetFrameSize.height
            )
            
            // 1. 프레임 이미지
            frameImage.draw(in: drawRect)
            
            // 2. 갈기 이미지
            if let maneImage = maneImage {
                maneImage.draw(in: drawRect)
            }
            
            // 3. 안장 이미지
            if let saddleImage = saddleImage {
                saddleImage.draw(in: drawRect)
            }
        }
    }
    
    // MARK: - Helper: Download Frame Image
    /// Nuke를 사용하여 프레임 이미지 다운로드
    private func downloadImage(from url: URL) async -> UIImage? {
        // Bundle에서 먼저 확인 (로컬 이미지인 경우)
        if url.scheme == nil || url.scheme == "file" {
            let imageName = url.lastPathComponent.replacingOccurrences(of: ".png", with: "")
            return UIImage(named: imageName)
        }

        // 원격 이미지 다운로드
        return await withCheckedContinuation { continuation in
            Task {
                do {
                    let imageRequest = ImageRequest(url: url)
                    let response = try await ImagePipeline.shared.image(for: imageRequest)
                    continuation.resume(returning: response)
                } catch {
                    print("Failed to download frame image: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
