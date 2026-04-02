//
//  LenticularHapticManager.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import UIKit

/// 렌티큘러 tilt 끝점 도달 시 햅틱 피드백
/// - tilt가 0(이미지 A 확정) 또는 1(이미지 B 확정) 근처에 도달하면 가볍게 진동
/// - 연속 트리거 방지: 한 번 발생 후 반대쪽으로 이동해야 다시 발생
final class LenticularHapticManager {

    /// 끝점 판정 임계값
    private let edgeLow: CGFloat = 0.01
    private let edgeHigh: CGFloat = 0.99

    /// 마지막으로 햅틱이 발생한 끝점 (nil이면 아직 미발생)
    private var lastTriggeredEdge: Edge?

    private let generator = UIImpactFeedbackGenerator(style: .light)

    private enum Edge {
        case low, high
    }

    init() {
        generator.prepare()
    }

    /// 매 프레임 tilt 값을 전달받아 끝점 도달 시 햅틱 발생
    func update(tilt: CGFloat) {
        if tilt <= edgeLow && lastTriggeredEdge != .low {
            generator.impactOccurred()
            lastTriggeredEdge = .low
        } else if tilt >= edgeHigh && lastTriggeredEdge != .high {
            generator.impactOccurred()
            lastTriggeredEdge = .high
        } else if tilt > edgeLow && tilt < edgeHigh {
            // 중간 영역 진입 시 리셋 — 다음 끝점에서 다시 트리거 가능
            if lastTriggeredEdge != nil {
                lastTriggeredEdge = nil
            }
        }
    }
}
