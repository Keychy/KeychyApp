//
//  AppIntent.swift
//  WidgetKeychy
//
//  위젯 표시 유형/항목 선택 Intent
//

import WidgetKit
import AppIntents
import SwiftUI

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

// MARK: - 애니메이션 토글 Intent

/// 위젯 터치 시 애니메이션을 (재)시작하는 인터랙티브 Intent
///
/// iOS 17+ `Button(intent:)` 와 함께 사용하여
/// 앱을 열지 않고 위젯 내에서 애니메이션을 재생한다.
///
/// 동작:
/// - 정지 중 → 탭 → 시작 시각 기록 → 30초간 애니메이션
/// - 재생 중 → 탭 → 시작 시각 갱신 → 처음부터 다시 30초 재생
/// - 30초 경과 → Timeline policy(.after)에 의해 자동 정지
struct ToggleAnimationIntent: AppIntent {
    static var title: LocalizedStringResource = "키링 애니메이션 토글"
    /// 위젯 내에서 실행 — 앱을 열지 않음
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Keyring ID")
    var keyringId: String

    /// 위젯 패밀리 ("small" / "large") — 같은 키링이라도 크기별로 애니메이션 상태 분리
    @Parameter(title: "Widget Family")
    var family: String

    static let animationDuration: TimeInterval = 30

    /// 애니메이션 상태 저장 키 생성 (keyringId + family 조합)
    static func animationKey(keyringId: String, family: String) -> String {
        "animStart_\(keyringId)_\(family)"
    }

    init() {}

    init(keyringId: String, family: String) {
        self.keyringId = keyringId
        self.family = family
    }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.keychy.app")!
        let key = Self.animationKey(keyringId: keyringId, family: family)

        // 항상 현재 시각으로 갱신 → 처음부터 (재)재생
        // 30초 후 자동 정지 (Timeline policy: .after)
        defaults.set(Date(), forKey: key)

        // 위젯 타임라인 리로드
        WidgetCenter.shared.reloadTimelines(ofKind: "WidgetKeychy")
        return .result()
    }
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
