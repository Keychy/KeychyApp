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

        // arcylic 기준으로 캔버스 크기 결정 (324pt 높이 기준)
        let targetHeight: CGFloat = 324
        let aspect = arcylicImage.size.width / arcylicImage.size.height
        let targetWidth = targetHeight * aspect
        let targetSize = CGSize(width: targetWidth, height: targetHeight)
        let drawRect = CGRect(origin: .zero, size: targetSize)

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        let composedImage = renderer.image { context in
            let cgContext = context.cgContext

            // 1. 아크릴 (입체감/그림자)
            arcylicImage.draw(in: drawRect)

            // 2. Color2 + base mask
            if let baseCG = baseMaskImage.cgImage {
                cgContext.saveGState()
                // CGContext의 clip(to:mask:)는 mask 이미지의 밝기를 기준으로 클리핑
                // 흰색(밝은) 부분 = 표시, 검은색(어두운) 부분 = 숨김
                cgContext.clip(to: drawRect, mask: baseCG)
                UIColor(uniformColor2).setFill()
                cgContext.fill(drawRect)
                cgContext.restoreGState()
            }

            // 3. Color1 + pattern mask (Firebase)
            if let patternCG = patternMaskImage.cgImage {
                cgContext.saveGState()
                cgContext.clip(to: drawRect, mask: patternCG)
                UIColor(uniformColor1).setFill()
                cgContext.fill(drawRect)
                cgContext.restoreGState()
            }

            // 4. stroke (외곽선)
            strokeImage.draw(in: drawRect)

            // 5. 등번호 그리기
            if !numberText.isEmpty {
                drawNumberText(in: drawRect, frame: frame)
            }

            // 6. 이름 그리기
            if !playerNameText.isEmpty {
                drawPlayerNameText(in: drawRect, frame: frame)
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
