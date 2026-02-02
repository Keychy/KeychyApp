//
//  WidgetKeychy.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import WidgetKit
import SwiftUI
import UIKit

// MARK: - Timeline Provider

struct KeyringWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> KeyringWidgetEntry {
        KeyringWidgetEntry(date: Date(), configuration: KeyringSelectionIntent())
    }

    func snapshot(for configuration: KeyringSelectionIntent, in context: Context) async -> KeyringWidgetEntry {
        KeyringWidgetEntry(date: Date(), configuration: KeyringSelectionIntent())
    }

    func timeline(for configuration: KeyringSelectionIntent, in context: Context) async -> Timeline<KeyringWidgetEntry> {
        let entry = KeyringWidgetEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .never)
    }
}

// MARK: - Widget Entry

struct KeyringWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: KeyringSelectionIntent
}

// MARK: - Widget

struct WidgetKeychy: Widget {
    let kind: String = "WidgetKeychy"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: KeyringSelectionIntent.self, provider: KeyringWidgetProvider()) { entry in
            KeyringWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Keychy 위젯")
        .description("위젯에 표시될 키링 또는 뭉치를 골라주세요")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

// MARK: - Entry View

struct KeyringWidgetEntryView: View {
    var entry: KeyringWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        // 뭉치가 선택된 경우 뭉치 표시
        if let bundle = entry.configuration.selectedBundle,
           let uiImage = loadBundleImage(bundleId: bundle.id) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(0.85)  // 뭉치 약간 작게
        }
        // 키링이 선택된 경우 키링 표시
        else if let keyring = entry.configuration.selectedKeyring,
           let uiImage = loadKeyringImage(keyringId: keyring.id) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                // 키링 기본 크기
        }
        // 아무것도 선택되지 않은 경우 placeholder
        else {
            placeholderView
        }
    }

    /// 뭉치 이미지 로드 (위젯용 우선, 없으면 full 버전 사용)
    private func loadBundleImage(bundleId: String) -> UIImage? {
        // 1. 위젯용 이미지 시도 (_widget.png)
        if let imageData = BundleImageCache.shared.loadImageByPath("\(bundleId)_widget.png"),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        // 2. Fallback: full 이미지 (.png)
        if let imageData = BundleImageCache.shared.loadImageByPath("\(bundleId).png"),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        return nil
    }

    /// 키링 이미지 로드 (위젯용 우선, 없으면 썸네일 사용)
    private func loadKeyringImage(keyringId: String) -> UIImage? {
        // 1. 위젯용 이미지 시도 (_widget.png)
        if let imageData = KeyringImageCache.shared.loadImageByPath("\(keyringId)_widget.png"),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        // 2. Fallback: 썸네일 이미지 (_thumb.png)
        if let imageData = KeyringImageCache.shared.loadImageByPath("\(keyringId)_thumb.png"),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        return nil
    }

    @ViewBuilder
    private var placeholderView: some View {
        if widgetFamily == .systemSmall {
            Image(.smallPlace)
                .resizable()
                .scaledToFill()
        } else {
            Image(.bigPlace)
                .resizable()
                .scaledToFill()
        }
    }
}
