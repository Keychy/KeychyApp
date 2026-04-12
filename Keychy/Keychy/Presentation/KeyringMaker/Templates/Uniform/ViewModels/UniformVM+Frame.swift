//
//  UniformVM+Frame.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//

import SwiftUI
import Nuke

extension UniformVM {

    // MARK: - Frame Composition

    /// 5레이어 mask 합성으로 유니폼 bodyImage 생성
    /// 레이어 순서: arcylic → color2+base → color1+pattern → stroke → 텍스트
    func composeUniformWithText() async {
        guard let frame = selectedFrame,
              let frameURL = URL(string: frame.frameURL) else {
            return
        }

        await MainActor.run {
            isComposingText = true
        }

        defer {
            Task { @MainActor in
                isComposingText = false
            }
        }

        let uniformType = frame.uniformType ?? "base"

        // 패턴 mask 이미지 다운로드 (Firebase)
        guard let patternMaskImage = await downloadFrameImage(from: frameURL) else {
            return
        }

        // 로컬 에셋 로드
        guard let arcylicImage = UIImage(named: "\(uniformType)_arcylic"),
              let baseMaskImage = UIImage(named: "\(uniformType)_base"),
              let strokeImage = UIImage(named: "\(uniformType)_stroke") else {
            return
        }

        // 프리뷰와 동일한 크기 비율 (arcylic > 나머지 레이어)
        let arcylicSize = CGSize(width: 302.03, height: 254.16)
        let layerSize = CGSize(width: 280, height: 205.5)

        // 캔버스 = 아크릴 크기 (고리가 y=0부터 시작하므로 잘림 없음)
        let canvasSize = arcylicSize
        let arcylicRect = CGRect(x: 1, y: 0, width: arcylicSize.width, height: arcylicSize.height)

        // 레이어 위치 (아크릴 기준 상대 배치)
        let layerX = (arcylicSize.width - layerSize.width) / 2 - 1.0
        let layerY = (arcylicSize.height - layerSize.height) / 2 + 14.5
        let layerRect = CGRect(x: layerX, y: layerY, width: layerSize.width, height: layerSize.height)

        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        let composedImage = renderer.image { context in
            // 1. 아크릴 (입체감/그림자)
            arcylicImage.draw(in: arcylicRect)

            // 2. Color2 + base mask
            let baseMasked = maskedColorImage(color: uniformColor2, mask: baseMaskImage, size: layerSize)
            baseMasked.draw(in: layerRect)

            // 3. Color1 + pattern mask (Firebase)
            let patternMasked = maskedColorImage(color: uniformColor1, mask: patternMaskImage, size: layerSize)
            patternMasked.draw(in: layerRect)

            // 4. stroke (외곽선)
            strokeImage.draw(in: layerRect)

            // 5. 등번호 그리기
            if !numberText.isEmpty {
                drawNumberText(in: layerRect, frame: frame)
            }

            // 6. 이름 그리기
            if !playerNameText.isEmpty {
                drawPlayerNameText(in: layerRect, frame: frame)
            }
        }

        bodyImage = composedImage
    }

    // MARK: - 등번호 텍스트 렌더링

    private func drawNumberText(in targetRect: CGRect, frame: Frame) {
        let numberFontSize = frame.numberFontSize ?? 60
        let numberOffsetY = frame.numberOffsetY ?? -20

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let strokeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: numberFontSize, weight: .bold),
            .foregroundColor: UIColor(numberOutlineColor),
            .strokeColor: UIColor(numberOutlineColor),
            .strokeWidth: -4.0,
            .paragraphStyle: paragraphStyle
        ]

        let fillAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: numberFontSize, weight: .bold),
            .foregroundColor: UIColor(numberInnerColor),
            .paragraphStyle: paragraphStyle
        ]

        let attrString = NSAttributedString(string: numberText, attributes: strokeAttributes)
        let textSize = attrString.boundingRect(
            with: CGSize(width: targetRect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            context: nil
        ).size

        let x = (targetRect.width - textSize.width) / 2
        let y = (targetRect.height - textSize.height) / 2 + numberOffsetY
        let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)

        // 테두리 → 내부 색상 순서로 그리기
        attrString.draw(in: textRect)
        NSAttributedString(string: numberText, attributes: fillAttributes).draw(in: textRect)
    }

    // MARK: - 이름 텍스트 렌더링

    private func drawPlayerNameText(in targetRect: CGRect, frame: Frame) {
        let baseFontSize = frame.nameFontSize ?? 24
        let nameOffsetY = frame.nameOffsetY ?? 40

        // 이름 길이에 따라 폰트 크기 자동 축소
        let charCount = playerNameText.count
        let adjustedFontSize: CGFloat
        if charCount <= 4 {
            adjustedFontSize = baseFontSize
        } else if charCount <= 6 {
            adjustedFontSize = baseFontSize * 0.85
        } else {
            adjustedFontSize = baseFontSize * 0.7
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let strokeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: adjustedFontSize, weight: .bold),
            .foregroundColor: UIColor(nameOutlineColor),
            .strokeColor: UIColor(nameOutlineColor),
            .strokeWidth: -3.0,
            .paragraphStyle: paragraphStyle
        ]

        let fillAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: adjustedFontSize, weight: .bold),
            .foregroundColor: UIColor(nameInnerColor),
            .paragraphStyle: paragraphStyle
        ]

        let attrString = NSAttributedString(string: playerNameText, attributes: strokeAttributes)
        let textSize = attrString.boundingRect(
            with: CGSize(width: targetRect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            context: nil
        ).size

        let x = (targetRect.width - textSize.width) / 2
        let y = (targetRect.height - textSize.height) / 2 + nameOffsetY
        let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)

        attrString.draw(in: textRect)
        NSAttributedString(string: playerNameText, attributes: fillAttributes).draw(in: textRect)
    }

    // MARK: - Helper: 색상 + mask 합성 이미지 생성

    /// 단색을 mask 이미지 모양으로 잘라낸 UIImage 반환
    /// UIImage.draw() + .destinationIn blend mode 사용 → CG 좌표계 뒤집힘 문제 없음
    private func maskedColorImage(color: Color, mask: UIImage, size: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // 먼저 단색으로 전체 채움
            UIColor(color).setFill()
            ctx.fill(rect)
            // destinationIn: mask의 불투명 영역만 색상을 남기고 나머지 투명 처리
            // mask를 1pt 크게 그려서 하단 보간 아티팩트가 캔버스 밖으로 클리핑되도록
            let maskRect = CGRect(x: 0, y: 0, width: size.width, height: size.height + 1)
            mask.draw(in: maskRect, blendMode: .destinationIn, alpha: 1.0)
        }
    }

    // MARK: - 유니폼 프레임 소유 여부 확인

    func isFrameOwned(_ frame: Frame) -> Bool {
        guard let frameId = frame.id else { return true }
        let price = frame.price ?? 0
        if price <= 0 { return true }
        return userManager.currentUser?.ownedUniformFrames.contains(frameId) ?? false
    }

    // MARK: - Helper: Download Frame Image

    /// Nuke를 사용하여 프레임 이미지 다운로드
    private func downloadFrameImage(from url: URL) async -> UIImage? {
        if url.scheme == nil || url.scheme == "file" {
            let imageName = url.lastPathComponent.replacingOccurrences(of: ".png", with: "")
            return UIImage(named: imageName)
        }

        do {
            return try await ImagePipeline.shared.image(for: ImageRequest(url: url))
        } catch {
            return nil
        }
    }
}
