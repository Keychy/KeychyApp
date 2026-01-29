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
    case myItems
    case workshopTemplates

    // MARK: - 번들 만들기
    case bundleInventoryView
    case bundleDetailView
    case bundleCreateView
    case bundleAddKeyringView
    case bundleNameInputView
    case bundleNameEditView
    case bundleEditView

    // MARK: - Festival 임시 라우트 (추후 정리 예정)
    case showcase25BoardView
    case festivalKeyringDetailView(Keyring)

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

    // MARK: - 선물 포장 완료
    case packageComplete(keyringDocumentId: String, postOfficeId: String)

    /// template.id 문자열을 WorkshopRoute로 변환
    static func from(string: String) -> WorkshopRoute? {
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
