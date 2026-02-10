//
//  TabBarSwipeObserver.swift
//  Keychy
//
//  Created by 길지훈 on 2/11/26.
//
//  스와이프 백 제스처 진행도를 탭바 투명도에 연동
//
//  [동작 흐름]
//  1. TabBarManager.hide() 호출 시 attach(to:) 실행
//  2. 스와이프 시작 → handleGesture 호출
//  3. 스와이프 진행 → 진행도(0~1)를 탭바 alpha에 반영
//  4. 스와이프 완료(50%↑ or 빠른 스와이프) → TabBarManager.show()
//  5. 스와이프 취소 → TabBarManager.hide()
//

import UIKit

final class TabBarSwipeObserver: NSObject {

    static let shared = TabBarSwipeObserver()

    // MARK: - Constants

    private enum Threshold {
        static let completeProgress: CGFloat = 0.5  // 50% 이상이면 완료
        static let fastVelocity: CGFloat = 500      // 빠른 스와이프 판정 속도
    }

    // MARK: - Properties

    private weak var currentGesture: UIGestureRecognizer?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Public

    /// 제스처에 옵저버 연결
    func attach(to gesture: UIGestureRecognizer) {
        guard currentGesture !== gesture else { return }

        detach()
        currentGesture = gesture
        gesture.addTarget(self, action: #selector(handleGesture(_:)))
    }

    /// 현재 제스처 연결 해제
    func detach() {
        currentGesture?.removeTarget(self, action: #selector(handleGesture(_:)))
        currentGesture = nil
    }

    // MARK: - Private

    private func calculateProgress(from gesture: UIPanGestureRecognizer) -> CGFloat {
        let translationX = gesture.translation(in: gesture.view).x
        let screenWidth = gesture.view?.window?.screen.bounds.width ?? gesture.view?.bounds.width ?? 393
        return min(max(translationX / screenWidth, 0), 1)
    }

    private func shouldComplete(progress: CGFloat, velocity: CGFloat) -> Bool {
        progress > Threshold.completeProgress || velocity > Threshold.fastVelocity
    }

    // MARK: - Gesture Handler

    @objc private func handleGesture(_ gesture: UIPanGestureRecognizer) {
        let progress = calculateProgress(from: gesture)

        switch gesture.state {
        case .changed:
            TabBarManager.setAlpha(progress)

        case .ended, .cancelled:
            let velocity = gesture.velocity(in: gesture.view).x
            if shouldComplete(progress: progress, velocity: velocity) {
                TabBarManager.show()
            } else {
                TabBarManager.hide()
            }

        default:
            break
        }
    }
}
