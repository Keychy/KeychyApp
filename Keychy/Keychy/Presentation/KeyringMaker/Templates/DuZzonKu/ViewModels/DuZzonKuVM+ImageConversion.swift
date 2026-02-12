//
//  DuZzonKuVM+ImageConversion.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI
import Nuke

extension DuZzonKuVM {
    
    // MARK: - Photo + Frame Composition (여러 개 지원)
    
    /// 선택한 사진들과 프레임을 합성하여 bodyImage로 저장
    func composePhotoWithFrame() async {
        guard let frame = selectedFrame,
              let frameURL = URL(string: frame.frameURL) else {
            return
        }
        
        // 합성 시작
        await MainActor.run {
            isComposingPhoto = true
        }
        
        defer {
            Task { @MainActor in
                isComposingPhoto = false
            }
        }
        
        // 프레임 이미지 다운로드
        guard let originalFrameImage = await downloadImage(from: frameURL) else {
            return
        }
        
        // 체커보드 이미지 다운로드 (선택사항)
        var checkerboardImage: UIImage? = nil
        if let checkerBoardURLString = frame.checkerBoardURL,
           let checkerBoardURL = URL(string: checkerBoardURLString) {
            checkerboardImage = await downloadImage(from: checkerBoardURL)
        }
        
        // DuZzonKuFramePreviewView와 동일한 크기로 합성
        let targetFrameHeight: CGFloat = 376
        let frameAspect = originalFrameImage.size.width / originalFrameImage.size.height
        let targetFrameWidth = targetFrameHeight * frameAspect
        let targetFrameSize = CGSize(width: targetFrameWidth, height: targetFrameHeight)
        
        // Firebase에서 정의한 체커보드 영역들
        guard let checkerBoardRects = frame.checkerBoardRects else {
            // checkerBoardRects가 없으면 프레임만 저장
            bodyImage = originalFrameImage
            return
        }
        
        let renderer = UIGraphicsImageRenderer(size: targetFrameSize)
        
        let composedImage = renderer.image { context in
            // 전체 context를 x축으로 4포인트 이동
            context.cgContext.translateBy(x: 2, y: 0)
            
            // 1. 각 체커보드 영역에 체커보드 + 사진 그리기
            for (index, rect) in checkerBoardRects.enumerated() {
                let photoWidth = targetFrameWidth * rect.width
                let photoHeight = targetFrameHeight * rect.height
                let photoX = targetFrameWidth * rect.x
                let photoY = targetFrameHeight * rect.y
                let photoRect = CGRect(x: photoX, y: photoY, width: photoWidth, height: photoHeight)
                
                // 1-1. 체커보드 배경 (선택사항)
                if let checkerboard = checkerboardImage {
                    context.cgContext.saveGState()
                    context.cgContext.addRect(photoRect)
                    context.cgContext.clip()
                    checkerboard.draw(in: photoRect)
                    context.cgContext.restoreGState()
                }
                
                // 1-2. 해당 인덱스의 사진 그리기
                if let photo = getPhoto(at: index) {
                    context.cgContext.saveGState()
                    
                    // cornerRadius 적용하여 클리핑
                    let cornerRadius = rect.cornerRadius ?? 0
                    let path = UIBezierPath(roundedRect: photoRect, cornerRadius: cornerRadius)
                    context.cgContext.addPath(path.cgPath)
                    context.cgContext.clip()
                    
                    // 사진을 영역에 맞게 scaledToFill로 그리기
                    let photoAspect = photo.size.width / photo.size.height
                    let rectAspect = photoRect.width / photoRect.height
                    
                    var drawRect = photoRect
                    if photoAspect > rectAspect {
                        // 사진이 더 넓음 - 높이 기준으로 맞춤
                        let scaledWidth = photoRect.height * photoAspect
                        drawRect = CGRect(
                            x: photoRect.midX - scaledWidth / 2,
                            y: photoRect.minY,
                            width: scaledWidth,
                            height: photoRect.height
                        )
                    } else {
                        // 사진이 더 높음 - 너비 기준으로 맞춤
                        let scaledHeight = photoRect.width / photoAspect
                        drawRect = CGRect(
                            x: photoRect.minX,
                            y: photoRect.midY - scaledHeight / 2,
                            width: photoRect.width,
                            height: scaledHeight
                        )
                    }
                    
                    // 해당 인덱스의 변환 적용
                    let photoScale = getPhotoScale(at: index)
                    let photoRotation = getPhotoRotation(at: index)
                    let photoOffset = getPhotoOffset(at: index)
                    
                    let centerX = drawRect.midX
                    let centerY = drawRect.midY
                    
                    context.cgContext.translateBy(x: centerX, y: centerY)
                    context.cgContext.translateBy(x: photoOffset.width + 2, y: photoOffset.height)
                    context.cgContext.rotate(by: CGFloat(photoRotation.radians))
                    context.cgContext.scaleBy(x: photoScale, y: photoScale)
                    
                    let centeredRect = CGRect(
                        x: -drawRect.width / 2,
                        y: -drawRect.height / 2,
                        width: drawRect.width,
                        height: drawRect.height
                    )
                    photo.draw(in: centeredRect)
                    context.cgContext.restoreGState()
                }
            }
            
            // 2. 프레임 이미지
            originalFrameImage.draw(in: CGRect(origin: .zero, size: targetFrameSize))
        }
        
        bodyImage = composedImage
    }
    
    // MARK: - Helper: Download Image
    
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
                    print("Failed to download image: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
