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
        let targetFrameHeight: CGFloat = 324
        let frameAspect = frameImage.size.width / frameImage.size.height
        let targetFrameWidth = targetFrameHeight * frameAspect
        let targetFrameSize = CGSize(width: targetFrameWidth, height: targetFrameHeight)
        
        let renderer = UIGraphicsImageRenderer(size: targetFrameSize)
        
        let composedImage = renderer.image { context in
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
        
        bodyImage = composedImage
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
