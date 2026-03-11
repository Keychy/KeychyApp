//
//  CrossStitchVM+ImageConversion.swift
//  Keychy
//
//  Created by Jini on 3/10/26.
//

import SwiftUI
import UIKit

// MARK: - Image Conversion
extension CrossStitchVM {

    /// 프레임 이미지 캐시
    private static var cachedFrameImage: UIImage?
    
    /// DrawView와 동일한 overlap 비율
    private enum RenderOverlap {
        static let horizontal: CGFloat = 0.22
        static let vertical: CGFloat   = 0.10
    }


    /// Firebase Storage에서 크로스스티치 프레임 이미지 다운로드
    func downloadCrossStitchFrame() async -> UIImage? {
        if let cached = Self.cachedFrameImage {
            return cached
        }

        let urlString = "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FCrossStitch%2FcrossStitchFrame.png?alt=media&token=40c5415d-a71b-426b-a89d-d10496944189"

        guard let url = URL(string: urlString) else {
            print("프레임 이미지 URL이 잘못되었습니다")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let image = UIImage(data: data) else {
                print("프레임 이미지 데이터를 UIImage로 변환 실패")
                return nil
            }

            Self.cachedFrameImage = image
            print("프레임 이미지 다운로드 및 캐싱 완료")
            return image

        } catch {
            print("프레임 이미지 다운로드 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// stitchGrid를 DrawView와 동일하게 overlap 적용해서 UIImage로 변환
    func convertGridToImage(cellSize: CGFloat = 20) -> UIImage? {
        let count = gridSize
        guard count > 0 else { return nil }

        let hOverlap = cellSize * RenderOverlap.horizontal
        let vOverlap = cellSize * RenderOverlap.vertical
        let renderW  = cellSize + hOverlap * 2   // 좌우 겹침 포함 렌더 너비
        let renderH  = cellSize + vOverlap * 2   // 상하 겹침 포함 렌더 높이

        // 가장자리 셀의 겹침 여백만큼 이미지 크기를 늘림 (DrawView와 동일)
        let totalInner = cellSize * CGFloat(count)
        let totalW = totalInner + hOverlap * 2
        let totalH = totalInner + vOverlap * 2
        let imageSize = CGSize(width: totalW, height: totalH)

        let renderer = UIGraphicsImageRenderer(size: imageSize)

        return renderer.image { _ in
            UIColor.clear.setFill()
            UIRectFill(CGRect(origin: .zero, size: imageSize))

            // DrawView와 동일하게 row+col 순서로 그려서 오른쪽/아래가 위에 쌓임
            for row in 0..<count {
                for col in 0..<count {
                    let stitchColor = stitchGrid[row][col]
                    let img = UIImage(resource: stitchColor.stitchImage)

                    // hOverlap/vOverlap 여백을 시작점으로 offset해서 가장자리가 잘리지 않도록
                    let centerX = hOverlap + (CGFloat(col) + 0.5) * cellSize
                    let centerY = vOverlap + (CGFloat(row) + 0.5) * cellSize

                    let rect = CGRect(
                        x: centerX - renderW / 2,
                        y: centerY - renderH / 2,
                        width: renderW,
                        height: renderH
                    )
                    img.draw(in: rect)
                }
            }
        }
    }

    /// 스티치 이미지와 프레임 이미지를 합성
    func composeWithFrame(stitchImage: UIImage, frameImage: UIImage) -> UIImage {
        let frameW = frameImage.size.width
        let frameH = frameImage.size.height
        let aspectRatio = frameH > 0 ? frameW / frameH : 1.0

        let canvasH: CGFloat = 200
        let canvasW: CGFloat = canvasH * aspectRatio
        let canvasSize = CGSize(width: canvasW, height: canvasH)

        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        return renderer.image { _ in
            // 1. 프레임 먼저 (배경)
            frameImage.draw(in: CGRect(origin: .zero, size: canvasSize))

            // 2. 스티치 이미지를 프레임 안쪽에 합성
            let topRatio:    CGFloat = 0.07
            let bottomRatio: CGFloat = 0.06
            let leftRatio:   CGFloat = 0.06
            let rightRatio:  CGFloat = 0.06

            let stitchRect = CGRect(
                x: canvasW * leftRatio,
                y: canvasH * topRatio,
                width: canvasW * (1 - leftRatio - rightRatio),
                height: canvasH * (1 - topRatio - bottomRatio)
            )
            stitchImage.draw(in: stitchRect)
        }
    }

    /// bodyImage 업데이트 (커스터마이징 뷰로 이동하기 전 호출)
    func updateBodyImage() async {
        // 1. 스티치 그리드를 이미지로 변환
        guard let stitchImg = convertGridToImage() else {
            print("스티치 이미지 생성 실패")
            return
        }

        // 2. 프레임 이미지 다운로드
        guard let frameImage = await downloadCrossStitchFrame() else {
            print("프레임 이미지 다운로드 실패 - 스티치 이미지만 사용")
            bodyImage = stitchImg
            hookOffsetY = 0
            return
        }

        // 3. 프레임과 스티치 이미지 합성
        bodyImage = composeWithFrame(stitchImage: stitchImg, frameImage: frameImage)
        hookOffsetY = 0.04
    }
}
