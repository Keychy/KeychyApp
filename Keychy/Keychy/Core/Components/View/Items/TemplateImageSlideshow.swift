//
//  TemplateImageSlideshow.swift
//  Keychy
//
//  Created by 길지훈 on 2026/02/13.
//

import SwiftUI
import NukeUI
import Nuke

/// 템플릿 프리뷰 이미지를 1초 간격으로 자동 순환하는 슬라이드 컴포넌트
///
/// - `localFirstImageName`이 있으면 번들 이미지를 즉시 표시 + 나머지만 네트워크 다운로드
/// - 번들 이미지가 없으면 전체를 네트워크에서 병렬 다운로드
/// - `.task` 기반 async 루프로 뷰 lifecycle에 바인딩 (사라지면 자동 cancel)
struct TemplateImageSlideshow: View {
    let imageURLs: [String]
    /// 앱 번들에 포함된 첫 번째 프리뷰 이미지 이름 (ex. "preview_AcrylicPhoto")
    var localFirstImageName: String? = nil

    @State private var currentIndex = 0
    @State private var loadedImages: [UIImage] = []

    /// 번들에서 찾은 첫 번째 이미지
    private var bundleFirstImage: UIImage? {
        guard let name = localFirstImageName else { return nil }
        return UIImage(named: name)
    }

    var body: some View {
        Group {
            if !loadedImages.isEmpty {
                Image(uiImage: loadedImages[currentIndex])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let bundleImage = bundleFirstImage {
                // 번들 이미지 즉시 표시 (네트워크 로딩 중)
                Image(uiImage: bundleImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let firstURL = imageURLs.first, let url = URL(string: firstURL) {
                // 번들 없음 → 첫 번째 URL을 LazyImage로 표시
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Color.gray50
                    }
                }
            } else {
                Color.gray50
            }
        }
        .task {
            await preloadAllImages()

            guard loadedImages.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                currentIndex = (currentIndex + 1) % loadedImages.count
            }
        }
    }

    /// 이미지를 UIImage 배열로 프리로드
    /// - 번들 이미지가 있으면: [번들이미지] + 네트워크[1...] (0번 스킵)
    /// - 번들 이미지가 없으면: 네트워크[0...] 전체 다운로드
    private func preloadAllImages() async {
        guard loadedImages.isEmpty else { return }

        let pipeline = ImagePipeline.shared
        let hasBundleFirst = bundleFirstImage != nil

        // 번들 이미지가 있으면 1번부터, 없으면 0번부터 다운로드
        let urlsToDownload = hasBundleFirst
            ? Array(imageURLs.dropFirst())
            : imageURLs

        let downloaded = await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, urlString) in urlsToDownload.enumerated() {
                guard let url = URL(string: urlString) else { continue }
                group.addTask {
                    let image = try? await pipeline.image(for: url)
                    return (index, image)
                }
            }

            var indexed: [(Int, UIImage)] = []
            for await (index, image) in group {
                if let image { indexed.append((index, image)) }
            }
            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }

        // 번들 이미지를 0번에 넣고 나머지 이어붙이기
        if hasBundleFirst, let first = bundleFirstImage {
            loadedImages = [first] + downloaded
        } else {
            guard !downloaded.isEmpty else { return }
            loadedImages = downloaded
        }
    }
}
