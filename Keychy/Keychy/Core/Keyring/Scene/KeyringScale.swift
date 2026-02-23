//
//  KeyringScale.swift
//  Keychy
//
//  Created by 길지훈 on 2/10/26.
//

import Foundation
import CoreGraphics

/// 키링 스케일 중앙 관리
/// - 템플릿별 maxSize
/// - 화면별 zoomScale
/// - 카라비너별 뭉치 키링 스케일
enum KeyringScale {

    // MARK: - 화면 종류
    enum Screen {
        case customizing    // 커스터마이징뷰
        case infoInput      // 정보입력뷰
        case complete       // 완성뷰
    }

    // MARK: - 템플릿별 maxSize
    private static let templateMaxSizes: [String: CGSize] = [
        "Polaroid": CGSize(width: 265, height: 324),
        "AcrylicPhoto": CGSize(width: 360, height: 360),
        "ClearSketch": CGSize(width: 210, height: 210),
        "PixelKeyring": CGSize(width: 277, height: 257),
        "SpeechBubble": CGSize(width: 360, height: 249),
        "WishHorse26": CGSize(width: 269, height: 310),
        "DuZzonKu": CGSize(width: 376, height: 376)
    ]

    // MARK: - 템플릿 × 화면별 zoomScale
    private static let templateZoomScales: [String: [Screen: CGFloat]] = [
        "Polaroid": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.7],
        "AcrylicPhoto": [.customizing: 1.0, .infoInput: 1.0, .complete: 1.0],
        "ClearSketch": [.customizing: 1.0, .infoInput: 1.0, .complete: 1.0],
        "PixelKeyring": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.9],
        "SpeechBubble": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.9],
        "WishHorse26": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.85],
        "DuZzonKu": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.8]
    ]

    // MARK: - 카라비너별 뭉치 키링 스케일
    private static let carabinerScales: [String: CGFloat] = [
        "CarouselOrgel": 0.5,
        "HeartPepero": 0.6,
        "HeartPlanet": 0.6,
        "MeltingWhiteChoco": 0.7,
        "UfoCat": 0.5,
    ]

    // MARK: - 기본값
    private static let defaultMaxSize = CGSize(width: 210, height: 210)
    private static let defaultZoomScale: CGFloat = 1.0
    private static let defaultCarabinerScale: CGFloat = 0.65

    // MARK: - Public API

    /// 템플릿별 maxSize 반환
    static func maxSize(for template: String) -> CGSize {
        return templateMaxSizes[template] ?? defaultMaxSize
    }

    /// 화면 × 템플릿별 zoomScale 반환
    static func zoomScale(for screen: Screen, template: String) -> CGFloat {
        return templateZoomScales[template]?[screen] ?? defaultZoomScale
    }

    /// 카라비너별 뭉치 키링 스케일 반환
    static func bundleKeyringScale(for carabiner: String) -> CGFloat {
        return carabinerScales[carabiner] ?? defaultCarabinerScale
    }
}
