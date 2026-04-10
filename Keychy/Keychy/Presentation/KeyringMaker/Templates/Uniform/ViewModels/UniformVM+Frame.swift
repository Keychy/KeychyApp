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

    /// 등번호 + 이름을 유니폼 프레임에 합성하여 bodyImage로 저장
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

        // 프레임 이미지 다운로드
        guard let originalFrameImage = await downloadFrameImage(from: frameURL) else {
            return
        }

        // 프레임 크기 조정 (324pt 높이 기준)
        let targetFrameHeight: CGFloat = 324
        let frameAspect = originalFrameImage.size.width / originalFrameImage.size.height
        let targetFrameWidth = targetFrameHeight * frameAspect
        let targetFrameSize = CGSize(width: targetFrameWidth, height: targetFrameHeight)

        let renderer = UIGraphicsImageRenderer(size: targetFrameSize)

        let composedImage = renderer.image { context in
            // 1. 프레임 이미지 그리기 (배경)
            originalFrameImage.draw(in: CGRect(origin: .zero, size: targetFrameSize))

            // 2. 등번호 그리기
            if !numberText.isEmpty {
                let numberFontSize = frame.numberFontSize ?? 60
                let numberOffsetY = frame.numberOffsetY ?? -20

                let numberParagraphStyle = NSMutableParagraphStyle()
                numberParagraphStyle.alignment = .center

                // 등번호 테두리 (strokeWidth 양수 = stroke만, 음수 = fill+stroke)
                let numberStrokeAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: numberFontSize, weight: .bold),
                    .foregroundColor: UIColor(numberOutlineColor),
                    .strokeColor: UIColor(numberOutlineColor),
                    .strokeWidth: -4.0,
                    .paragraphStyle: numberParagraphStyle
                ]

                let numberFillAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: numberFontSize, weight: .bold),
                    .foregroundColor: UIColor(numberInnerColor),
                    .paragraphStyle: numberParagraphStyle
                ]

                let numberString = NSAttributedString(string: numberText, attributes: numberStrokeAttributes)
                let numberSize = numberString.boundingRect(
                    with: CGSize(width: targetFrameSize.width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin],
                    context: nil
                ).size

                let numberX = (targetFrameSize.width - numberSize.width) / 2
                let numberY = (targetFrameSize.height - numberSize.height) / 2 + numberOffsetY

                let numberRect = CGRect(x: numberX, y: numberY, width: numberSize.width, height: numberSize.height)

                // 테두리 먼저 그리고 내부 색상 덮기
                numberString.draw(in: numberRect)
                NSAttributedString(string: numberText, attributes: numberFillAttributes).draw(in: numberRect)
            }

            // 3. 이름 그리기
            if !playerNameText.isEmpty {
                let baseFontSize = frame.nameFontSize ?? 24
                let nameOffsetY = frame.nameOffsetY ?? 40

                // 이름 길이에 따라 폰트 크기 자동 축소
                let adjustedFontSize: CGFloat
                let charCount = playerNameText.count
                if charCount <= 4 {
                    adjustedFontSize = baseFontSize
                } else if charCount <= 6 {
                    adjustedFontSize = baseFontSize * 0.85
                } else {
                    adjustedFontSize = baseFontSize * 0.7
                }

                let nameParagraphStyle = NSMutableParagraphStyle()
                nameParagraphStyle.alignment = .center

                let nameStrokeAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: adjustedFontSize, weight: .bold),
                    .foregroundColor: UIColor(nameOutlineColor),
                    .strokeColor: UIColor(nameOutlineColor),
                    .strokeWidth: -3.0,
                    .paragraphStyle: nameParagraphStyle
                ]

                let nameFillAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: adjustedFontSize, weight: .bold),
                    .foregroundColor: UIColor(nameInnerColor),
                    .paragraphStyle: nameParagraphStyle
                ]

                let nameString = NSAttributedString(string: playerNameText, attributes: nameStrokeAttributes)
                let nameSize = nameString.boundingRect(
                    with: CGSize(width: targetFrameSize.width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin],
                    context: nil
                ).size

                let nameX = (targetFrameSize.width - nameSize.width) / 2
                let nameY = (targetFrameSize.height - nameSize.height) / 2 + nameOffsetY

                let nameRect = CGRect(x: nameX, y: nameY, width: nameSize.width, height: nameSize.height)

                nameString.draw(in: nameRect)
                NSAttributedString(string: playerNameText, attributes: nameFillAttributes).draw(in: nameRect)
            }
        }

        bodyImage = composedImage
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

        return await withCheckedContinuation { continuation in
            Task {
                do {
                    let imageRequest = ImageRequest(url: url)
                    let response = try await ImagePipeline.shared.image(for: imageRequest)
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
