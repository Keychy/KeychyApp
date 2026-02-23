//
//  WorkshopRoute.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//
import Foundation

/// 공방 탭 라우팅 (마켓플레이스 + 키링 제작)
enum WorkshopRoute: Hashable, BundleRoute {
    // MARK: - 공방 마켓플레이스
    case workshopPreview(item: AnyHashable)
    case coinCharge
    case workshopTemplates

    // MARK: - 번들 만들기
    case bundleInventoryView
    case bundleDetailView
    case bundleCreateView
    case bundleNameInputView
    case bundleNameEditView
    case bundleEditView
    case bundleCompleteView

    // MARK: - 아크릴 포토 템플릿
    case acrylicPhotoPreview
    case acrylicPhotoCrop
    case acrylicPhotoEdited
    case acrylicPhotoCustomizing
    case acrylicPhotoInfoInput
    case acrylicPhotoComplete

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
    
    // MARK: - 2026을 말해봐 키링 템플릿
    case wishHorse26Preview
    case wishHorse26Customizing
    case wishHorse26InfoInput
    case wishHorse26Complete
    
    // MARK: - 두쫀쿠 키링 템플릿
    case duZzonKuPreview
    case duZzonKuCustomizing
    case duZzonKuInfoInput
    case duZzonKuComplete

    // MARK: - 선물 포장 완료
    case packageComplete(keyringDocumentId: String, postOfficeId: String, templateId: String, shareLink: String)

    // MARK: - 위젯 가이딩
    case widgetSettingView
    
    /// template.id 문자열을 WorkshopRoute로 변환
    static func from(string: String) -> WorkshopRoute? {
        switch string {
        case "AcrylicPhoto":
            return .acrylicPhotoPreview
        case "Polaroid":
            return .polaroidPreview
        case "ClearSketch":
            return .clearSketchPreview
        case "PixelKeyring":
            return .pixelPreview
        case "SpeechBubble":
            return .speechBubblePreview
        case "WishHorse26":
            return .wishHorse26Preview
        case "DuZzonKu":
            return .duZzonKuPreview
        default:
            return nil
        }
    }
}
