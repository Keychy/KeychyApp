//
//  LenticularMotionManager.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import CoreMotion
import Foundation

/// 렌티큘러 셰이더용 자이로센서 래퍼 (싱글톤)
/// - Apple 권장: CMMotionManager 인스턴스는 앱 전체에서 1개만 사용
/// - 참조 카운팅으로 여러 Scene에서 공유 시 자동 start/stop
@Observable
final class LenticularMotionManager {

    static let shared = LenticularMotionManager()

    /// 셰이더 uniform용 (0.0~1.0)
    private(set) var tilt: CGFloat = 0.0

    /// 부호 유지 (-1.0~+1.0) — 햅틱/3D 회전에 활용
    private(set) var signedTilt: CGFloat = 0.0

    // MARK: - Private

    private let manager = CMMotionManager()
    private var calibrationRoll: Double = 0.0

    /// 0~range 라디안을 0~1로 매핑 (~50°)
    private let range: Double = 0.87
    private let updateInterval: TimeInterval = 1.0 / 60.0

    /// 참조 카운팅: 0이면 센서 정지, 1 이상이면 센서 가동
    private var referenceCount = 0
    private var isRunning = false

    private init() {}

    // MARK: - 참조 카운팅 API

    /// Scene이 나타날 때 호출 — refCount 증가, 0→1이면 센서 시작
    func start() {
        referenceCount += 1
        guard referenceCount == 1 else { return }
        startMotionUpdates()
    }

    /// Scene이 사라질 때 호출 — refCount 감소, 1→0이면 센서 정지
    func stop() {
        referenceCount = max(referenceCount - 1, 0)
        guard referenceCount == 0 else { return }
        stopMotionUpdates()
    }

    /// 현재 자세를 기준점으로 재설정
    func recalibrate() {
        calibrationRoll = manager.deviceMotion?.attitude.roll ?? 0.0
    }

    // MARK: - 센서 제어

    private func startMotionUpdates() {
        guard !isRunning, manager.isDeviceMotionAvailable else { return }
        isRunning = true
        manager.deviceMotionUpdateInterval = updateInterval

        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let roll = motion.attitude.roll

            // 최초 캘리브레이션
            if self.calibrationRoll == 0.0 {
                self.calibrationRoll = roll
            }

            // 좌우(roll) 고정 — 키링이 체인에 매달려 좌우로 흔들리는 것과 동기
            let normalized = (roll - self.calibrationRoll) / self.range
            self.tilt = CGFloat(min(abs(normalized), 1.0))
            self.signedTilt = CGFloat(max(min(normalized, 1.0), -1.0))
        }
    }

    private func stopMotionUpdates() {
        manager.stopDeviceMotionUpdates()
        isRunning = false
        tilt = 0.0
        signedTilt = 0.0
    }
}
