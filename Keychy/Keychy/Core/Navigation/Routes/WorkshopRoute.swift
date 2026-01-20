//
//  WorkshopRoute.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//
import Foundation

/// 공방 탭 라우팅 (마켓플레이스 기능)
enum WorkshopRoute: Hashable {
    // MARK: - 공방 마켓플레이스
    case workshopPreview(item: AnyHashable)
    case coinCharge
    case myItems
    case workshopTemplates

    // MARK: - Festival 임시 라우트 (추후 정리 예정)
    case showcase25BoardView
    case festivalKeyringDetailView(Keyring)
}
