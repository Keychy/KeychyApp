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
        let numberFontSize = frame.numberFontSize ?? 75
        let numberOffsetY = frame.numberOffsetY ?? -20
        let numberFont = UIFont(name: FontFamily.bmdohyeon.fontName, size: numberFontSize)
            ?? UIFont.systemFont(ofSize: numberFontSize, weight: .bold)

        let textSize = measureText(numberText, font: numberFont, maxWidth: targetRect.width)

        let x = targetRect.origin.x + (targetRect.width - textSize.width) / 2
        let y = targetRect.origin.y + (targetRect.height - textSize.height) / 2 + numberOffsetY
        let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)

        drawOutlinedText(
            numberText,
            font: numberFont,
            innerColor: UIColor(numberInnerColor),
            outlineColor: UIColor(numberOutlineColor),
            outlineWidth: 5.4,
            in: textRect
        )
    }

    // MARK: - 이름 텍스트 렌더링 (곡률 적용)

    private func drawPlayerNameText(in targetRect: CGRect, frame: Frame) {
        let baseFontSize = nameFontSize
        let nameOffsetY = frame.nameOffsetY ?? 40

        // 이름 길이에 따라 폰트 크기 자동 축소
        let charCount = playerNameText.count
        let adjustedFontSize: CGFloat
        if charCount <= 4 {
            adjustedFontSize = baseFontSize
        } else if charCount <= 6 {
            adjustedFontSize = baseFontSize * 0.85
        } else if charCount <= 8 {
            adjustedFontSize = baseFontSize * 0.72
        } else {
            adjustedFontSize = baseFontSize * 0.62
        }

        let nameFont = UIFont(name: FontFamily.esamanruMedium.fontName, size: adjustedFontSize)
            ?? UIFont.systemFont(ofSize: adjustedFontSize, weight: .bold)

        // 곡률 정규화: 0.16 → 0 (직선), 0.84 → 1 (최대 곡선)
        let normalized = (textCurvature - 0.16) / (0.84 - 0.16)

        // 중간 이상 곡률에서 이름을 위로 올려 등번호와 겹침 방지
        let nameUpshift: CGFloat = max(normalized - 0.3, 0) / 0.7 * 14.0
        let adjustedNameOffsetY = nameOffsetY - nameUpshift

        if normalized < 0.01 {
            // 최소 곡률: 직선 텍스트 (원래 자간 유지)
            let textSize = measureText(playerNameText, font: nameFont, maxWidth: targetRect.width)
            let x = targetRect.origin.x + (targetRect.width - textSize.width) / 2
            let y = targetRect.origin.y + (targetRect.height - textSize.height) / 2 + adjustedNameOffsetY
            let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)

            drawOutlinedText(
                playerNameText,
                font: nameFont,
                innerColor: UIColor(nameInnerColor),
                outlineColor: UIColor(nameOutlineColor),
                outlineWidth: 3.86,
                in: textRect
            )
        } else {
            // 곡선 텍스트 (곡률에 비례한 자간)
            let centerX = targetRect.origin.x + targetRect.width / 2
            let centerY = targetRect.origin.y + targetRect.height / 2 + adjustedNameOffsetY

            drawCurvedOutlinedText(
                playerNameText,
                font: nameFont,
                innerColor: UIColor(nameInnerColor),
                outlineColor: UIColor(nameOutlineColor),
                outlineWidth: 3.86,
                centerX: centerX,
                centerY: centerY,
                curvature: textCurvature
            )
        }
    }

    // MARK: - Helper: 호(Arc) 위에 아웃라인 텍스트 렌더링

    /// 각 문자를 원호 위에 개별 배치 + 32방향 오프셋 아웃라인
    /// curvature → radius 변환: radius = 80 / curvature (0.16=거의 직선, 0.84=강한 곡선)
    private func drawCurvedOutlinedText(
        _ text: String,
        font: UIFont,
        innerColor: UIColor,
        outlineColor: UIColor,
        outlineWidth: CGFloat,
        centerX: CGFloat,
        centerY: CGFloat,
        curvature: CGFloat,
        directions: Int = 32
    ) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let radius = 55.0 / max(curvature, 0.01)
        // 호 중심을 텍스트 아래에 배치 → 가장자리가 아래로 휘는 곡선
        let arcCenterY = centerY + radius

        // 각 문자의 너비 측정
        let chars = Array(text)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let charWidths = chars.map { char in
            NSAttributedString(string: String(char), attributes: attrs).size().width
        }
        let totalWidth = charWidths.reduce(0, +)
        // 총 각도 = 문자열 폭 / 반지름 (호의 길이 = 반지름 × 각도)
        let totalAngle = totalWidth / radius

        // 곡률 정규화 (0.16 → 0, 0.84 → 1) → 자간을 0에서 점진적으로 증가
        let normalized = (curvature - 0.16) / (0.84 - 0.16)
        let letterSpacing: CGFloat = 8.0 * normalized
        let spacedTotalWidth = totalWidth + letterSpacing * CGFloat(chars.count - 1)
        let totalAngleWithSpacing = spacedTotalWidth / radius

        // 12시(−π/2) 기준 좌우 대칭으로 시작
        var currentAngle = -CGFloat.pi / 2 - totalAngleWithSpacing / 2

        let outlineAttrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: outlineColor
        ]
        let fillAttrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: innerColor
        ]
        let textHeight = font.ascender - font.descender

        for i in 0..<chars.count {
            let charStr = String(chars[i])
            let charWidth = charWidths[i]
            let charAngle = charWidth / radius
            // 글자 간격 포함한 각도
            let spacedCharAngle = (charWidth + letterSpacing) / radius
            let midAngle = currentAngle + spacedCharAngle / 2

            // 호 위의 좌표
            let x = centerX + radius * cos(midAngle)
            let y = arcCenterY + radius * sin(midAngle)

            ctx.saveGState()
            ctx.translateBy(x: x, y: y)
            // 접선 방향으로 회전
            ctx.rotate(by: midAngle + CGFloat.pi / 2)

            // 문자 중심을 변환 원점에 맞추기 위한 드로잉 포인트
            let drawPoint = CGPoint(x: -charWidth / 2, y: -textHeight / 2)

            // 아웃라인 (32방향 오프셋)
            let outlineStr = NSAttributedString(string: charStr, attributes: outlineAttrs)
            for d in 0..<directions {
                let a = CGFloat(d) * (2 * CGFloat.pi / CGFloat(directions))
                let dx = cos(a) * outlineWidth
                let dy = sin(a) * outlineWidth
                outlineStr.draw(at: CGPoint(x: drawPoint.x + dx, y: drawPoint.y + dy))
            }

            // 내부 색상
            NSAttributedString(string: charStr, attributes: fillAttrs)
                .draw(at: drawPoint)

            ctx.restoreGState()

            currentAngle += spacedCharAngle
        }
    }

    // MARK: - Helper: 텍스트 크기 측정

    private func measureText(_ text: String, font: UIFont, maxWidth: CGFloat) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return NSAttributedString(string: text, attributes: attributes)
            .boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                context: nil
            ).size
    }

    // MARK: - Helper: N방향 오프셋 아웃라인 텍스트 렌더링

    /// SwiftUI OutlineText와 동일한 방식 — 32방향 오프셋 복사본으로 두꺼운 아웃라인 생성
    /// NSAttributedString.strokeWidth는 폰트 크기의 %라서 얇게 나오므로, 이 방식이 프리뷰와 일치함
    private func drawOutlinedText(
        _ text: String,
        font: UIFont,
        innerColor: UIColor,
        outlineColor: UIColor,
        outlineWidth: CGFloat,
        in textRect: CGRect,
        directions: Int = 32
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let outlineAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: outlineColor,
            .paragraphStyle: paragraphStyle
        ]

        let fillAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: innerColor,
            .paragraphStyle: paragraphStyle
        ]

        let outlineString = NSAttributedString(string: text, attributes: outlineAttributes)
        let fillString = NSAttributedString(string: text, attributes: fillAttributes)

        // 32방향 원형 오프셋으로 아웃라인 렌더링 (OutlineText와 동일 알고리즘)
        for i in 0..<directions {
            let angle = CGFloat(i) * (2 * CGFloat.pi / CGFloat(directions))
            let dx = cos(angle) * outlineWidth
            let dy = sin(angle) * outlineWidth
            outlineString.draw(in: textRect.offsetBy(dx: dx, dy: dy))
        }

        // 내부 색상을 위에 덮어씀
        fillString.draw(in: textRect)
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
