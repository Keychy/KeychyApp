//
//  WidgetKeychy.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import WidgetKit
import SwiftUI
import AppIntents
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
        let defaults = UserDefaults(suiteName: "group.keychy.app")
        let familyString = context.family == .systemSmall ? "small" : "large"

        // 애니메이션 상태 확인 (키링 타입일 때만)
        if configuration.displayType == .keyring,
           let keyring = configuration.selectedKeyring,
           let defaults = defaults {

            let animKey = ToggleAnimationIntent.animationKey(
                keyringId: keyring.id, family: familyString
            )

            if let startTime = defaults.object(forKey: animKey) as? Date {
                let elapsed = Date().timeIntervalSince(startTime)

                if elapsed < ToggleAnimationIntent.animationDuration {
                    let stopDate = startTime.addingTimeInterval(ToggleAnimationIntent.animationDuration)
                    let frames = AnimationFrameStorage.loadFrames(keyringID: keyring.id)

                    let entry = KeyringWidgetEntry(
                        date: Date(),
                        configuration: configuration,
                        isAnimating: true,
                        animationFrames: frames,
                        animationStartDate: startTime
                    )
                    return Timeline(entries: [entry], policy: .after(stopDate))
                } else {
                    // 30초 지남 → 애니메이션 키 제거
                    defaults.removeObject(forKey: animKey)
                }
            }
        }

        // 정적 모드
        let entry = KeyringWidgetEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .never)
    }
}

// MARK: - Widget Entry

struct KeyringWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: KeyringSelectionIntent
    var isAnimating: Bool = false
    var animationFrames: [UIImage]? = nil
    var animationStartDate: Date? = nil
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
        .description("위젯에 표시할 유형을 선택한 후, 항목을 골라주세요.")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

// MARK: - Entry View

struct KeyringWidgetEntryView: View {
    var entry: KeyringWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch entry.configuration.displayType {
        case .keyring:
            keyringView
        case .bundle:
            bundleView
        }
    }

    // MARK: - 키링 뷰

    @ViewBuilder
    private var keyringView: some View {
        let familyString = widgetFamily == .systemSmall ? "small" : "large"

        if let keyring = entry.configuration.selectedKeyring {
            if entry.isAnimating,
               let frames = entry.animationFrames,
               let startDate = entry.animationStartDate {
                // BlinkMask 폰트 마스킹 애니메이션
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)
                    AnimatedKeyringView(
                        frames: frames,
                        size: size,
                        referenceDate: startDate
                    )
                }
                .overlay {
                    Button(intent: ToggleAnimationIntent(keyringId: keyring.id, family: familyString)) {
                        Color.clear
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } else if let uiImage = loadKeyringImage(keyringId: keyring.id) {
                // 정적 이미지 → 탭 시 애니메이션 시작
                if AnimationFrameStorage.hasFrames(keyringID: keyring.id) {
                    Button(intent: ToggleAnimationIntent(keyringId: keyring.id, family: familyString)) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
            } else {
                placeholderView
            }
        } else {
            placeholderView
        }
    }

    // MARK: - 뭉치 뷰

    @ViewBuilder
    private var bundleView: some View {
        if let bundle = entry.configuration.selectedBundle,
           let uiImage = loadBundleImage(bundleId: bundle.id) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(0.85)
        } else {
            placeholderView
        }
    }

    // MARK: - 이미지 로드

    private func loadBundleImage(bundleId: String) -> UIImage? {
        if let imageData = BundleImageCache.shared.loadImageByPath("\(bundleId)_widget.png"),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        if let imageData = BundleImageCache.shared.loadImageByPath("\(bundleId).png"),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        return nil
    }

    private func loadKeyringImage(keyringId: String) -> UIImage? {
        if let imageData = KeyringImageCache.shared.loadImageByPath("\(keyringId)_widget.png"),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        if let imageData = KeyringImageCache.shared.loadImageByPath("\(keyringId)_thumb.png"),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        }
        return nil
    }

    // MARK: - 플레이스홀더

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
