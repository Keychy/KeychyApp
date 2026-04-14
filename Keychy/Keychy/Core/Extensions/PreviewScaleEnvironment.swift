//
//  PreviewScaleEnvironment.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-13.
//

import SwiftUI

// MARK: - 프리뷰 스케일 팩터 Environment Key
// iPhone 16 Pro (852pt) 기준 → 작은 기기에서 비율 유지하며 축소

private struct PreviewScaleFactorKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

// MARK: - 프리뷰 상단 패딩 Environment Key
// SpriteKit 카메라 줌 보정된 키링 위치와 프레임탭 위치를 동기화

private struct PreviewTopPaddingKey: EnvironmentKey {
    static let defaultValue: CGFloat = 85.2 // 852 * 0.1 (기준 기기 기본값)
}

extension EnvironmentValues {
    var previewScaleFactor: CGFloat {
        get { self[PreviewScaleFactorKey.self] }
        set { self[PreviewScaleFactorKey.self] = newValue }
    }

    var previewTopPadding: CGFloat {
        get { self[PreviewTopPaddingKey.self] }
        set { self[PreviewTopPaddingKey.self] = newValue }
    }
}
