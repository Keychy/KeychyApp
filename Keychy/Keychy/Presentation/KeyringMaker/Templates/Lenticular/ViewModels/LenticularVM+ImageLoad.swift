//
//  LenticularVM+ImageLoad.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import SwiftUI
import PhotosUI

extension LenticularVM {

    /// 두 이미지 모두 선택되었는지
    var canProceed: Bool {
        imageA != nil && imageB != nil
    }

    /// PhotosPickerItem에서 UIImage를 로드하여 대상 이미지에 설정
    @MainActor
    func loadImage(from item: PhotosPickerItem?, target: ImageTarget) async {
        guard let item else { return }

        isLoadingImage = true
        defer { isLoadingImage = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        switch target {
        case .a:
            imageA = uiImage
            photoScaleA = 1.0
            photoOffsetA = .zero
        case .b:
            imageB = uiImage
            photoScaleB = 1.0
            photoOffsetB = .zero
        }
    }

    /// 이미지가 카드 영역을 벗어나지 않는 최대 오프셋 계산
    /// - scaledToFill 기준으로 이미지가 카드를 덮는 범위에서만 이동 가능
    func maxOffset(for target: ImageTarget, scale: CGFloat, cardSize: CGSize) -> CGSize {
        guard let image = (target == .a ? imageA : imageB) else { return .zero }

        // scaledToFill: 짧은 축이 카드에 맞춰지므로 큰 비율 사용
        let fillScale = max(cardSize.width / image.size.width,
                            cardSize.height / image.size.height)
        let displayedWidth = image.size.width * fillScale * scale
        let displayedHeight = image.size.height * fillScale * scale

        return CGSize(
            width: max((displayedWidth - cardSize.width) / 2, 0),
            height: max((displayedHeight - cardSize.height) / 2, 0)
        )
    }

    /// 오프셋 클램핑 (이미지가 카드를 항상 완전히 덮도록)
    private func clampedOffset(_ offset: CGSize, maxOffset: CGSize) -> CGSize {
        CGSize(
            width: min(max(offset.width, -maxOffset.width), maxOffset.width),
            height: min(max(offset.height, -maxOffset.height), maxOffset.height)
        )
    }

    /// 핀치 제스처 종료 시 스케일 적용 + 오프셋 재클램핑
    /// - cardSize는 composeAtlas의 좌표계 변환을 위해 VM에도 저장됨
    func applyScale(_ gestureScale: CGFloat, target: ImageTarget, cardSize: CGSize) {
        sourceCardSize = cardSize
        switch target {
        case .a:
            photoScaleA = min(max(photoScaleA * gestureScale, 1.0), 3.0)
            let maxOff = maxOffset(for: .a, scale: photoScaleA, cardSize: cardSize)
            photoOffsetA = clampedOffset(photoOffsetA, maxOffset: maxOff)
        case .b:
            photoScaleB = min(max(photoScaleB * gestureScale, 1.0), 3.0)
            let maxOff = maxOffset(for: .b, scale: photoScaleB, cardSize: cardSize)
            photoOffsetB = clampedOffset(photoOffsetB, maxOffset: maxOff)
        }
    }

    /// 드래그 제스처 종료 시 오프셋 적용 (클램핑 포함)
    /// - cardSize는 composeAtlas의 좌표계 변환을 위해 VM에도 저장됨
    func applyOffset(_ translation: CGSize, target: ImageTarget, cardSize: CGSize) {
        sourceCardSize = cardSize
        switch target {
        case .a:
            let maxOff = maxOffset(for: .a, scale: photoScaleA, cardSize: cardSize)
            photoOffsetA = clampedOffset(
                CGSize(width: photoOffsetA.width + translation.width,
                       height: photoOffsetA.height + translation.height),
                maxOffset: maxOff
            )
        case .b:
            let maxOff = maxOffset(for: .b, scale: photoScaleB, cardSize: cardSize)
            photoOffsetB = clampedOffset(
                CGSize(width: photoOffsetB.width + translation.width,
                       height: photoOffsetB.height + translation.height),
                maxOffset: maxOff
            )
        }
    }

    // MARK: - 아틀라스 합성

    /// 사용자 크롭(스케일/오프셋) 적용 후 A+B 아틀라스 합성 → bodyImage에 저장
    ///
    /// offset이 `sourceCardSize` 좌표계 기준이므로 `targetSize` 좌표계로 변환이 필요하다.
    /// `sourceCardSize`는 `applyScale`/`applyOffset` 호출 시 VM이 자동으로 기록한다.
    /// 사용자가 카드를 한 번도 편집하지 않으면 `sourceCardSize`가 `.zero`로 남는데,
    /// 이 경우 `cropImage`가 폴백 처리하여 기본 위치(중앙 정렬)로 그린다.
    func composeAtlas() {
        guard let a = imageA, let b = imageB else { return }
        let targetSize = KeyringScale.maxSize(for: templateId)

        let croppedA = cropImage(a, scale: photoScaleA, offset: photoOffsetA, targetSize: targetSize)
        let croppedB = cropImage(b, scale: photoScaleB, offset: photoOffsetB, targetSize: targetSize)

        // 썸네일 등 편집 결과를 보여주는 뷰에서 재사용
        croppedImageA = croppedA
        croppedImageB = croppedB

        bodyImage = TextureComposer.compose(
            imageA: croppedA,
            imageB: croppedB,
            targetSize: targetSize
        )
    }

    /// 이미지에 사용자 크롭(스케일/오프셋)을 적용하여 targetSize로 렌더링
    ///
    /// 핵심: 사용자의 offset은 `sourceCardSize` 좌표계에서 캡처된 값이므로,
    /// `targetSize` 좌표계로 그릴 때는 두 fillScale의 비율만큼 변환해야 한다.
    /// 변환 공식: `convertedOffset = offset × (fillScale_target / fillScale_source)`
    private func cropImage(
        _ image: UIImage,
        scale: CGFloat,
        offset: CGSize,
        targetSize: CGSize
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            // target 좌표계의 fillScale (실제 그리기에 사용)
            let fillScale = max(targetSize.width / image.size.width,
                                targetSize.height / image.size.height)
            let drawSize = CGSize(
                width: image.size.width * fillScale * scale,
                height: image.size.height * fillScale * scale
            )

            // source 좌표계의 fillScale (사용자 offset이 기반으로 하는 좌표계)
            let sourceFillScale = max(sourceCardSize.width / image.size.width,
                                      sourceCardSize.height / image.size.height)
            // 두 좌표계 비율 — source → target 변환 계수
            // sourceCardSize가 아직 기록되지 않았으면 변환 없이 원점에 그림 (이 경우 offset은 .zero일 것)
            let ratio = sourceFillScale > 0 ? (fillScale / sourceFillScale) : 1.0

            let convertedOffset = CGSize(
                width: offset.width * ratio,
                height: offset.height * ratio
            )

            let drawOrigin = CGPoint(
                x: (targetSize.width - drawSize.width) / 2 + convertedOffset.width,
                y: (targetSize.height - drawSize.height) / 2 + convertedOffset.height
            )
            image.draw(in: CGRect(origin: drawOrigin, size: drawSize))
        }
    }

    enum ImageTarget {
        case a, b
    }
}
