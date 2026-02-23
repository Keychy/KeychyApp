//
//  LottieItemView.swift
//  Keychy
//
//  Created by 길지훈 on 2/11/26.
//

import SwiftUI
import Lottie

/// 배경/카라비너 Lottie 아이템 표시용 뷰
/// - JSON 파싱을 백그라운드 스레드에서 비동기 수행 (메인 스레드 블로킹 방지)
/// - NSCache 기반 인메모리 캐시로 동일 에셋 재파싱 방지
/// - Coordinator 패턴으로 LottieAnimationView 생명주기 관리
struct LottieItemView: UIViewRepresentable {
    let assetId: String
    let directory: String
    let loopMode: LottieLoopMode
    let contentMode: UIView.ContentMode

    // MARK: - 인메모리 캐시
    /// LottieAnimation.filepath()는 JSON 파싱 비용이 큼
    /// NSCache로 파싱 결과를 메모리에 유지하여 같은 에셋 재파싱 방지
    /// NSCache는 thread-safe이므로 별도 lock 불필요
    private static let animationCache = NSCache<NSString, AnimationWrapper>()

    /// NSCache는 class 타입만 저장 가능 → LottieAnimation을 래핑
    private class AnimationWrapper {
        let animation: LottieAnimation
        init(_ animation: LottieAnimation) { self.animation = animation }
    }

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

    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var animationView: LottieAnimationView?
        var loadTask: Task<Void, Never>?
    }

    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.clipsToBounds = true

        let animationView = LottieAnimationView()
        animationView.contentMode = contentMode
        context.coordinator.animationView = animationView

        container.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: container.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: container.heightAnchor)
        ])

        // JSON 파싱을 백그라운드 스레드에서 비동기 수행
        // Task.detached: 현재 actor 컨텍스트를 상속하지 않으므로 백그라운드에서 실행됨
        let assetId = self.assetId
        let directory = self.directory
        let loopMode = self.loopMode

        context.coordinator.loadTask = Task.detached(priority: .userInitiated) {
            let animation = Self.loadAnimation(assetId: assetId, directory: directory)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard !Task.isCancelled, let animation else { return }
                animationView.animation = animation
                animationView.loopMode = loopMode
                animationView.play()
            }
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    /// 뷰 제거 시 비동기 Task 취소 + 애니메이션 정지 + 메모리 해제
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.loadTask?.cancel()
        coordinator.loadTask = nil
        coordinator.animationView?.stop()
        coordinator.animationView?.animation = nil
        coordinator.animationView?.removeFromSuperview()
        coordinator.animationView = nil
    }

    // MARK: - Animation Loading
    /// 인메모리 캐시 → 디스크 순서로 LottieAnimation 로드
    /// 백그라운드 스레드에서 호출되므로 메인 스레드를 블로킹하지 않음
    private static func loadAnimation(assetId: String, directory: String) -> LottieAnimation? {
        let key = "\(directory)/\(assetId)" as NSString

        // 1. 인메모리 캐시 히트 → 즉시 반환 (JSON 재파싱 없음)
        if let cached = animationCache.object(forKey: key) {
            return cached.animation
        }

        // 2. 디스크에서 로드 (JSON 파싱 발생)
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDir.appendingPathComponent("\(directory)/\(assetId).json")
        guard FileManager.default.fileExists(atPath: cachedURL.path),
              let animation = LottieAnimation.filepath(cachedURL.path) else { return nil }

        // 3. 인메모리 캐시에 저장
        animationCache.setObject(AnimationWrapper(animation), forKey: key)

        return animation
    }

    // MARK: - Cache Invalidation
    /// 특정 에셋의 인메모리 캐시 무효화
    /// LottieItemManager에서 새 파일 다운로드 완료 시 호출
    static func invalidateCache(assetId: String, directory: String) {
        let key = "\(directory)/\(assetId)" as NSString
        animationCache.removeObject(forKey: key)
    }
}
