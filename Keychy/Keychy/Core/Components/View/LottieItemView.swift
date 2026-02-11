//
//  LottieItemView.swift
//  Keychy
//
//  Created by 길지훈 on 2/11/26.
//

import SwiftUI
import Lottie
import NukeUI

/// 배경/카라비너 Lottie 아이템 표시용 뷰
/// - LottieView와 달리 캐시 경로를 파라미터로 받아 범용 사용
/// - Lottie 로드 실패 시 fallbackImageURL로 정적 이미지 표시
struct LottieItemView: UIViewRepresentable {
    let assetId: String
    let directory: String
    let loopMode: LottieLoopMode
    let contentMode: UIView.ContentMode

    private let animationView = LottieAnimationView()

    init(
        assetId: String,
        directory: String,
        loopMode: LottieLoopMode = .loop,
        contentMode: UIView.ContentMode = .scaleAspectFill
    ) {
        self.assetId = assetId
        self.directory = directory
        self.loopMode = loopMode
        self.contentMode = contentMode
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.clipsToBounds = true

        if let animation = findAnimation() {
            animationView.animation = animation
            animationView.contentMode = contentMode
            animationView.loopMode = loopMode
            animationView.play()
        }

        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    /// 캐시 디렉토리에서 Lottie 애니메이션 찾기
    private func findAnimation() -> LottieAnimation? {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("\(directory)/\(assetId).json")

        guard FileManager.default.fileExists(atPath: cachedURL.path) else { return nil }
        return LottieAnimation.filepath(cachedURL.path)
    }
}
