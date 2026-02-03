//
//  BundleSwitchPopup.swift
//  Keychy
//
//  Created by Claude on 2/3/26.
//

import SwiftUI

/// 홈 화면에서 뭉치를 변경할 수 있는 드롭다운 팝업
struct BundleSwitchPopup: View {
    let bundles: [KeyringBundle]
    let currentBundle: KeyringBundle?
    let onSelect: (KeyringBundle) -> Void

    /// 대표 뭉치 (isMain == true)
    private var mainBundle: KeyringBundle? {
        bundles.first(where: { $0.isMain })
    }

    /// 선택 가능한 뭉치들 (대표 제외)
    private var selectableBundles: [KeyringBundle] {
        bundles.filter { !$0.isMain }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 대표 섹션
            if let main = mainBundle {
                sectionHeader("대표")
                bundleRow(bundle: main, isSelected: currentBundle?.documentId == main.documentId)
            }

            // 선택 섹션
            if !selectableBundles.isEmpty {
                sectionHeader("선택")

                ForEach(selectableBundles, id: \.documentId) { bundle in
                    bundleRow(bundle: bundle, isSelected: currentBundle?.documentId == bundle.documentId)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(width: 160)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
    }

    // MARK: - Subviews

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .typography(.suit13M)
            .foregroundStyle(.gray400)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func bundleRow(bundle: KeyringBundle, isSelected: Bool) -> some View {
        Button {
            onSelect(bundle)
        } label: {
            HStack {
                Text(bundle.name)
                    .typography(isSelected ? .suit17B : .suit17M)
                    .foregroundStyle(isSelected ? .main500 : .black100)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.main500)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 드롭다운 버튼
struct BundleSwitchButton: View {
    let bundleName: String
    let isExpanded: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(bundleName)
                    .typography(.suit17SB)
                    .foregroundStyle(.black100)

                if isEnabled {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.gray500)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
