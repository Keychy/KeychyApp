//
//  KeyringMakerRoute.swift
//  Keychy
//
//  키링 제작 모듈 라우팅
//

import Foundation

/// 키링 제작(KeyringMaker) 모듈 라우팅
enum KeyringMakerRoute: Hashable {
    // MARK: - 아크릴 포토 템플릿
    case acrylicPhotoPreview
    case acrylicPhotoCrop
    case acrylicPhotoEdited
    case acrylicPhotoCustomizing
    case acrylicPhotoInfoInput
    case acrylicPhotoComplete

    // MARK: - 네온 사인 템플릿
    case neonSignPreview
    case neonSignCustomizing
    case neonSignInfoInput
    case neonSignComplete

    // MARK: - 폴라로이드 템플릿
    case polaroidPreview
    case polaroidCustomizing
    case polaroidInfoInput
    case polaroidComplete

    // MARK: - 클리어 스케치 템플릿
    case clearSketchPreview
    case clearSketchDrawing
    case clearSketchCrop
    case clearSketchCustomizing
    case clearSketchInfoInput
    case clearSketchComplete

    // MARK: - 픽셀 키링 템플릿
    case pixelPreview
    case pixelDraw
    case pixelCustomizing
    case pixelInfoInput
    case pixelComplete

    // MARK: - 말풍선 키링 템플릿
    case speechBubblePreview
    case speechBubbleCustomizing
    case speechBubbleInfoInput
    case speechBubbleComplete

    // MARK: - 공통
    case coinCharge

    /// template.id 문자열을 KeyringMakerRoute로 변환
    static func from(string: String) -> KeyringMakerRoute? {
        switch string {
        case "AcrylicPhoto":
            return .acrylicPhotoPreview
        case "NeonSign":
            return .neonSignPreview
        case "Polaroid":
            return .polaroidPreview
        case "ClearSketch":
            return .clearSketchPreview
        case "PixelKeyring":
            return .pixelPreview
        case "SpeechBubble":
            return .speechBubblePreview
        default:
            return nil
        }
    }
}
