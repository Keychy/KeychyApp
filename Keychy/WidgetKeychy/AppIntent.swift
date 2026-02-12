//
//  AppIntent.swift
//  WidgetKeychy
//
//  위젯 표시 유형/항목 선택 Intent
//

import WidgetKit
import AppIntents

// MARK: - 표시 유형 (키링 / 뭉치)

enum DisplayType: String, AppEnum {
    case keyring = "keyring"
    case bundle = "bundle"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "표시 유형"

    static var caseDisplayRepresentations: [DisplayType: DisplayRepresentation] = [
        .keyring: "키링",
        .bundle: "뭉치"
    ]
}

// MARK: - Keyring Entity

struct KeyringEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "키링"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = KeyringEntityQuery()
}

struct KeyringEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [KeyringEntity] {
        let keyrings = KeyringImageCache.shared.loadWidgetKeyrings()
        return identifiers.compactMap { id in
            keyrings.first(where: { $0.id == id })
                .map { KeyringEntity(id: $0.id, name: $0.name) }
        }
    }

    func suggestedEntities() async throws -> [KeyringEntity] {
        KeyringImageCache.shared.loadWidgetKeyrings()
            .sorted { $0.createdAt > $1.createdAt }
            .map { KeyringEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> KeyringEntity? { nil }
}

// MARK: - Bundle Entity

struct BundleEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "뭉치"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = BundleEntityQuery()
}

struct BundleEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [BundleEntity] {
        let bundles = BundleImageCache.shared.loadWidgetBundleModels()
        return identifiers.compactMap { id in
            bundles.first(where: { $0.id == id })
                .map { BundleEntity(id: $0.id, name: $0.name) }
        }
    }

    func suggestedEntities() async throws -> [BundleEntity] {
        BundleImageCache.shared.loadWidgetBundleModels()
            .sorted { $0.createdAt > $1.createdAt }
            .map { BundleEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> BundleEntity? { nil }
}

// MARK: - Selection Intent

struct KeyringSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "위젯 설정" }
    static var description: IntentDescription { "위젯에 표시할 유형과 항목을 선택하세요" }

    @Parameter(title: "표시 유형", default: .keyring)
    var displayType: DisplayType

    @Parameter(title: "키링 선택")
    var selectedKeyring: KeyringEntity?

    @Parameter(title: "뭉치 선택")
    var selectedBundle: BundleEntity?

    static var parameterSummary: some ParameterSummary {
        When(\KeyringSelectionIntent.$displayType, .equalTo, .keyring) {
            Summary("표시 유형: \(\.$displayType)") {
                \.$selectedKeyring
            }
        } otherwise: {
            Summary("표시 유형: \(\.$displayType)") {
                \.$selectedBundle
            }
        }
    }
}
