//
//  WidgetKeychy.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import WidgetKit
import SwiftUI

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
        .description("위젯에 표시될 키링을 골라주세요")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

// MARK: - Entry View

struct KeyringWidgetEntryView: View {
    var entry: KeyringWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if let keyring = entry.configuration.selectedKeyring,
           let imageData = KeyringImageCache.shared.loadImageByPath("\(keyring.id)_thumb.png"),
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            placeholderView
        }
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
