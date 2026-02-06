//
//  AppIntent.swift
//  WidgetKeychy
//
//  위젯 키링/뭉치 선택 Intent
//

import WidgetKit
import AppIntents

// MARK: - Keyring Entity

/// 위젯에서 선택 가능한 키링
struct KeyringEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "키링"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = KeyringEntityQuery()
}

// MARK: - Keyring Entity Query

/// App Group에서 키링 목록 조회
struct KeyringEntityQuery: EntityQuery {
    /// ID로 키링 찾기 (위젯 복원 시 사용)
    func entities(for identifiers: [String]) async throws -> [KeyringEntity] {
        let widgetKeyrings = KeyringImageCache.shared.loadWidgetKeyrings()
        return widgetKeyrings
            .filter { identifiers.contains($0.id) }
            .map { KeyringEntity(id: $0.id, name: $0.name) }
    }

    /// 선택 가능한 키링 목록 (최신순)
    func suggestedEntities() async throws -> [KeyringEntity] {
        let widgetKeyrings = KeyringImageCache.shared.loadWidgetKeyrings()
            .sorted { $0.createdAt > $1.createdAt }
        return widgetKeyrings.map { KeyringEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> KeyringEntity? {
        nil
    }
}

// MARK: - Bundle Entity

/// 위젯에서 선택 가능한 뭉치
struct BundleEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "뭉치"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = BundleEntityQuery()
}

// MARK: - Bundle Entity Query

/// App Group에서 뭉치 목록 조회
struct BundleEntityQuery: EntityQuery {
    /// ID로 뭉치 찾기 (위젯 복원 시 사용)
    func entities(for identifiers: [String]) async throws -> [BundleEntity] {
        let widgetBundles = BundleImageCache.shared.loadWidgetBundleModels()
        return widgetBundles
            .filter { identifiers.contains($0.id) }
            .map { BundleEntity(id: $0.id, name: $0.name) }
    }

    /// 선택 가능한 뭉치 목록 (최신순)
    func suggestedEntities() async throws -> [BundleEntity] {
        let widgetBundles = BundleImageCache.shared.loadWidgetBundleModels()
            .sorted { $0.createdAt > $1.createdAt }
        return widgetBundles.map { BundleEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> BundleEntity? {
        nil
    }
}

// MARK: - Selection Intent

/// 위젯 키링/뭉치 선택 인텐트
struct KeyringSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "키링/뭉치 선택" }
    static var description: IntentDescription { "위젯에 표시할 키링 또는 뭉치를 선택하세요" }

    @Parameter(title: "키링")
    var selectedKeyring: KeyringEntity?

    @Parameter(title: "뭉치")
    var selectedBundle: BundleEntity?
}
