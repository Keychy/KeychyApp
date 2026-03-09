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

        if configuration.displayType == .keyring,
           let keyring = configuration.selectedKeyring {

            let frames = AnimationFrameStorage.loadFrames(keyringID: keyring.id)

            // 애니메이션 상태 확인 (같은 키링이면 크기 무관하게 동기화)
            if let defaults = defaults {
                let animKey = ToggleAnimationIntent.animationKey(
                    keyringId: keyring.id
                )

                if let startTime = defaults.object(forKey: animKey) as? Date {
                    let elapsed = Date().timeIntervalSince(startTime)

                    if elapsed < ToggleAnimationIntent.animationDuration {
                        let stopDate = startTime.addingTimeInterval(ToggleAnimationIntent.animationDuration)

                        // 애니메이션 엔트리 (지금)
                        let animEntry = KeyringWidgetEntry(
                            date: Date(),
                            configuration: configuration,
                            isAnimating: true,
                            animationFrames: frames,
                            animationStartDate: startTime
                        )
                        // 정지 엔트리 (stopDate에 자동 전환) — frame[0]만 유지
                        let stopEntry = KeyringWidgetEntry(
                            date: stopDate,
                            configuration: configuration,
                            animationFrames: frames?.first.map { [$0] }
                        )
                        return Timeline(entries: [animEntry, stopEntry], policy: .never)
                    } else {
                        defaults.removeObject(forKey: animKey)
                    }
                }
            }

            // 정적 모드 — Intent 실행 후 WidgetKit이 자동 타임라인 리로드
            let entry = KeyringWidgetEntry(
                date: Date(),
                configuration: configuration,
                animationFrames: frames
            )
            return Timeline(entries: [entry], policy: .never)
        }

        // 키링 외 (뭉치 등)
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
        if let keyring = entry.configuration.selectedKeyring,
           let frames = entry.animationFrames,
           !frames.isEmpty {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)

                if entry.isAnimating,
                   let startDate = entry.animationStartDate {
                    AnimatedKeyringView(
                        frames: frames,
                        size: size,
                        startDate: startDate
                    )
                } else {
                    Image(uiImage: frames[0])
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                }
            }
            .overlay {
                Button(intent: ToggleAnimationIntent(keyringId: keyring.id)) {
                    Color.clear
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
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
