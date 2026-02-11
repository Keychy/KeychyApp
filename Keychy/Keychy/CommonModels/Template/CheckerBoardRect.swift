//
//  CheckerBoardRect.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import Foundation

/// 체커보드의 실제 영역 정보 (프레임 기준 비율)
struct CheckerBoardRect: Codable, Identifiable, Hashable {
    /// 고유 ID (Firebase 자동 생성 또는 순서)
    var id: String?
    
    /// X 위치 (프레임 너비 기준 비율, 0.0 ~ 1.0)
    var x: CGFloat
    
    /// Y 위치 (프레임 높이 기준 비율, 0.0 ~ 1.0)
    var y: CGFloat
    
    /// 너비 (프레임 너비 기준 비율, 0.0 ~ 1.0)
    var width: CGFloat
    
    /// 높이 (프레임 높이 기준 비율, 0.0 ~ 1.0)
    var height: CGFloat
    
    /// 모서리 radius
    var cornerRadius: CGFloat?
    
    /// 순서 (여러 개일 때 정렬용)
    var order: Int?
}
