//
//  KeyringScale.swift
//  Keychy
//
//  Created by 길지훈 on 2/10/26.
//

import Foundation
import CoreGraphics
import UIKit

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
        case video          // 영상생성용
    }

    // MARK: - 템플릿별 maxSize
    private static let templateMaxSizes: [String: CGSize] = [
        "Polaroid": CGSize(width: 265, height: 324),
        "AcrylicPhoto": CGSize(width: 360, height: 360),
        "ClearSketch": CGSize(width: 210, height: 230),
        "PixelKeyring": CGSize(width: 277, height: 277),
        "SpeechBubble": CGSize(width: 360, height: 249),
        "WishHorse26": CGSize(width: 280, height: 310),
        "DuZzonKu": CGSize(width: 376, height: 376),
        "CrossStitch": CGSize(width: 258, height: 258),
        "Lenticular": CGSize(width: 220, height: 270),
        "Uniform": CGSize(width: 310, height: 260)
    ]

    // MARK: - 템플릿 × 화면별 zoomScale
    private static let templateZoomScales: [String: [Screen: CGFloat]] = [
        "Polaroid": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.7, .video: 0.8],
        "AcrylicPhoto": [.customizing: 1.0, .infoInput: 1.0, .complete: 1.0, .video: 0.8],
        "ClearSketch": [.customizing: 1.0, .infoInput: 1.0, .complete: 1.0, .video: 0.8],
        "PixelKeyring": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.9, .video: 0.8],
        "SpeechBubble": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.9, .video: 0.8],
        "WishHorse26": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.85, .video: 0.8],
        "DuZzonKu": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.8, .video: 0.8],
        "CrossStitch": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.9, .video: 0.8],
        "Lenticular": [.customizing: 0.85, .infoInput: 0.85, .complete: 0.7, .video: 0.8],
        "Uniform": [.customizing: 1.0, .infoInput: 1.0, .complete: 0.9, .video: 1.0]
    ]

    // MARK: - 카라비너별 뭉치 키링 스케일
    private static let carabinerScales: [String: CGFloat] = [
        "CarouselOrgel": 0.5,
        "HeartPepero": 0.6,
        "HeartPlanet": 0.6,
        "MeltingWhiteChoco": 0.7,
        "UfoCat": 0.5,
        "YellowPin": 0.6,
        "RedPin": 0.6,
        "MintPin": 0.5,
        "PurplePin": 0.5,
        "CheeseNyangi": 0.6,
        "GrayNyangi": 0.6,
        "BlackNyangi": 0.6,
        "Baduki": 0.6,
        "Baekgu": 0.6,
        "Nureungi": 0.6,
    ]
    
    // MARK: - 템플릿별 뭉치 키링 스케일
    private static let templateBodyScales: [String: CGFloat] = [
        "Polaroid":     0.85,
        "AcrylicPhoto": 1.0,
        "ClearSketch":  1.0,
        "PixelKeyring": 0.7,
        "SpeechBubble": 1.0,
        "WishHorse26":  1.0,
        "DuZzonKu":     0.9,
        "CrossStitch":  0.7,
        "Uniform":      0.9
    ]

    // MARK: - 위젯 출력 크기 (템플릿별)
    /// 위젯 프레임 합성 후 최종 축소 크기 (px)
    /// PNG 복잡도가 높은 템플릿은 낮춰서 30MB 제한 회피
    private static let templateWidgetOutputSize: [String: Int] = [
        "CrossStitch": 400,
        "PixelKeyring": 400,
        "Lenticular": 500
    ]

    // MARK: - 위젯 바디 클램프 비율 (템플릿별)
    /// 위젯 합성 시 바디 오버플로 방지용 최대 비율 (frameSize 대비)
    /// 값이 클수록 바디가 크게 표시됨
    private static let templateWidgetBodyClamp: [String: CGFloat] = [
        "CrossStitch": 0.55,
        "PixelKeyring": 0.55,
        "Polaroid": 0.6,
        "Lenticular": 0.6
    ]

    // MARK: - 위젯 바디 Y 보정값 (템플릿별)
    /// 위젯 합성 시 바디이미지 Y축 위치 보정 (음수 = 위로, 양수 = 아래로)
    private static let templateWidgetBodyOffsetY: [String: CGFloat] = [
        "Polaroid": -30,
        "AcrylicPhoto": -200,
        "ClearSketch": -180,
        "PixelKeyring": -40,
        "SpeechBubble": -60,
        "welcome": -40,
        "WishHorse26": -110,
        "DuZzonKu": -40,
        "CrossStitch": -30,
        "Lenticular": -30,
        "Uniform": -40
    ]

    // MARK: - 렌티큘러 3D 회전 상수
    /// FusionView rotation3DEffect용 (SwiftUI 레벨)
    static let lenticularTiltMultiplier: Double = 20
    /// FusionView rotation3DEffect perspective 값
    static let lenticularTiltPerspective: CGFloat = 0.6

    /// SKTransformNode yRotation 최대 각도 (라디안)
    /// signedTilt(-1~+1) × lenticularYRotationMax = 실제 회전 각도
    /// 기본값 35° = 0.611 rad (디바이스 테스트 후 조정 가능)
    static let lenticularYRotationMax: CGFloat = 35 * .pi / 180

    /// SKTransformNode xRotation 최대 각도 (라디안) — 수직 기울기용
    /// 체인이 앞뒤로 안 움직이므로 은근한 입체감 수준으로 제한
    static let lenticularXRotationMax: CGFloat = 12 * .pi / 180

    // MARK: - 기본값
    private static let defaultMaxSize = CGSize(width: 210, height: 210)
    private static let defaultZoomScale: CGFloat = 1.0
    private static let defaultCarabinerScale: CGFloat = 0.65
    private static let defaultTemplateBodyScale: CGFloat = 1.0
    private static let defaultWidgetBodyOffsetY: CGFloat = 0
    private static let defaultWidgetOutputSize: Int = 500
    private static let defaultWidgetBodyClamp: CGFloat = 0.7

    // MARK: - Public API

    /// 템플릿별 maxSize 반환
    static func maxSize(for template: String) -> CGSize {
        return templateMaxSizes[template] ?? defaultMaxSize
    }

    /// 화면 × 템플릿별 zoomScale 반환
    static func zoomScale(for screen: Screen, template: String) -> CGFloat {
        return templateZoomScales[template]?[screen] ?? defaultZoomScale
    }

    /// 카라비너별 뭉치 키링 스케일 반환 (링, 체인, 바디 공통)
    static func bundleKeyringScale(for carabiner: String) -> CGFloat {
        return carabinerScales[carabiner] ?? defaultCarabinerScale
    }
    
    /// 템플릿별 뭉치 바디 추가 스케일 (바디에만 적용)
    static func bundleBodyScale(for template: String?) -> CGFloat {
        return templateBodyScales[template ?? ""] ?? defaultTemplateBodyScale
    }

    /// 위젯 합성 시 템플릿별 바디 Y 보정값 반환
    /// - bodyImage: WishHorse26 type A(기울어진) 판별용 (세로가 더 길면 type A)
    static func widgetBodyOffsetY(for template: String, bodyImage: UIImage? = nil) -> CGFloat {
        if template == "WishHorse26", let image = bodyImage {
            let isTilted = image.size.height > image.size.width
            return isTilted ? -100 : -120
        }
        return templateWidgetBodyOffsetY[template] ?? defaultWidgetBodyOffsetY
    }

    /// 위젯 합성 시 바디 클램프 비율 반환 (frameSize 대비)
    static func widgetBodyClamp(for template: String) -> CGFloat {
        return templateWidgetBodyClamp[template] ?? defaultWidgetBodyClamp
    }

    /// 위젯 프레임 합성 후 최종 출력 크기 반환
    static func widgetOutputSize(for template: String) -> Int {
        return templateWidgetOutputSize[template] ?? defaultWidgetOutputSize
    }
}
