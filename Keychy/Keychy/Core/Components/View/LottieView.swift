//
//  LottieView.swift
//  KeytschPrototype
//
//  Created by rundo on 10/21/25.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let speed: CGFloat

    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var animationView: LottieAnimationView?
    }

    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)

        let animationView = LottieAnimationView()
        context.coordinator.animationView = animationView

        if let animation = findParticleAnimation(particleId: name) {
            animationView.animation = animation
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = loopMode
            animationView.animationSpeed = speed
            animationView.play()
        }

        container.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: container.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: container.heightAnchor)
        ])
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    /// 뷰 제거 시 애니메이션 정지 + 메모리 해제
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.animationView?.stop()
        coordinator.animationView?.animation = nil
        coordinator.animationView?.removeFromSuperview()
        coordinator.animationView = nil
    }

    // MARK: - Private
    private func findParticleAnimation(particleId: String) -> LottieAnimation? {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

        if FileManager.default.fileExists(atPath: cachedURL.path) {
            return LottieAnimation.filepath(cachedURL.path)
        }

        if let animation = LottieAnimation.named(particleId) {
            return animation
        }

        return nil
    }
}
