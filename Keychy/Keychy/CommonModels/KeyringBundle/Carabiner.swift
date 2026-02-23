//
//  Carabiner.swift
//  Keychy
//
//  Created by 김서현 on 10/27/25.
//

import Foundation
import FirebaseFirestore
import CoreGraphics

/// Firebase Firestore에서 가져오는 카라비너 모델
/// - Collection: carabiners/{carabinerId}
struct Carabiner: Identifiable, Codable, Equatable, Hashable {
    /// Document ID
    @DocumentID var id: String?
    
    /// 카라비너 이름
    let carabinerName: String
    
    /// 카라비너 이미지 URL
    /// - [0] : 합체 이미지 (썸네일용)
    /// - [1] : 뒷 이미지
    /// - [2] : 앞 이미지
    let carabinerImage: [String]

    /// 카라비너 Lottie JSON URL 배열 (nil이면 정적 이미지)
    /// - plain: [0] = 단일 Lottie
    /// - hamburger: [0] = 썸네일, [1] = 뒷면, [2] = 앞면
    let carabinerLottie: [String]?

    /// 카라비너 타입
    /// - .hamburger : 벽걸이 형
    /// - .plain : 일반 카라비너 형
    let carabinerType: String
    
    /// 카라비너 설명
    let description: String
    
    /// 걸 수 있는 키링 최대 개수
    let maxKeyringCount: Int
    
    /// 카라비너 분류 태그 (ex. ["귀여움", "#키워드"])
    let tags: [String]
    
    /// 추천 조합
    let recommendedCombinations: String?
    
    /// 구매 시 필요한 코인 (0이면 무료)
    let price: Int
    
    /// 다운로드 횟수
    let downloadCount: Int
    
    /// 사용 횟수
    let useCount: Int
    
    /// 생성일
    let createdAt: Date

    /// 앱 노출 여부 (false면 앱에서 숨김)
    let isActive: Bool

    /// 카라비너 왼쪽상단 좌표
    let carabinerX: CGFloat
    
    let carabinerY: CGFloat
    
    let carabinerWidth: CGFloat
    
    /// 키링 x위치 배열
    let keyringXPosition: [CGFloat]
    
    /// 키링 y위치 배열
    let keyringYPosition: [CGFloat]
    
    /// Lottie 아이템 여부
    var isLottie: Bool {
        carabinerLottie != nil && !(carabinerLottie?.isEmpty ?? true)
    }

    /// 무료 카라비너 여부
    var isFree: Bool {
        return price == 0
    }

    /// 카라비너 타입 enum
    var type: CarabinerType {
        return CarabinerType.from(carabinerType)
    }
    
    /// 뒷면(또는 단일) 카라비너 이미지 URL
    var backImageURL: String {
        switch type {
        case .hamburger:
            return carabinerImage.count > 1 ? carabinerImage[1] : ""
        case .plain:
            return carabinerImage.count > 0 ? carabinerImage[0] : ""
        }
    }
    
    /// 앞면 카라비너 이미지 URL (햄버거 타입만)
    var frontImageURL: String? {
        guard type == .hamburger, carabinerImage.count > 2 else {
            return nil
        }
        return carabinerImage[2]
    }
    
    /// 썸네일 이미지 URL
    var thumbnailImageURL: String {
        return carabinerImage.first ?? ""
    }

    /// 뒷면 Lottie URL (plain: [0], hamburger: [1])
    var backLottieURL: String? {
        guard isLottie else { return nil }
        switch type {
        case .hamburger:
            return carabinerLottie?.count ?? 0 > 1 ? carabinerLottie?[1] : nil
        case .plain:
            return carabinerLottie?.count ?? 0 > 0 ? carabinerLottie?[0] : nil
        }
    }

    /// 앞면 Lottie URL (hamburger 타입만)
    var frontLottieURL: String? {
        guard isLottie, type == .hamburger,
              let lottie = carabinerLottie, lottie.count > 2 else {
            return nil
        }
        return lottie[2]
    }
}
