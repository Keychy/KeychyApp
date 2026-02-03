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
                mainSection(bundle: main)
            }

            // 구분선
            Rectangle()
                .fill(.gray100)
                .frame(height: 1)
                .padding(.horizontal, 18)

            // 선택 섹션
            if !selectableBundles.isEmpty {
                selectSection(bundles: selectableBundles)
            }
        }
        .frame(width: 196)
        .padding(.vertical, 5)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
    }

    // MARK: - 대표 섹션

    private func mainSection(bundle: KeyringBundle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("대표")
                .typography(.suit13M)
                .foregroundStyle(.gray200)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)

            Button {
                onSelect(bundle)
            } label: {
                HStack {
                    Text(bundle.name)
                        .typography(.suit16M)
                        .foregroundStyle(currentBundle?.documentId == bundle.documentId ? .gray600 : .gray400)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 선택 섹션

    private func selectSection(bundles: [KeyringBundle]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("선택")
                .typography(.suit13M)
                .foregroundStyle(.gray200)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 25) {
                ForEach(bundles, id: \.documentId) { bundle in
                    Button {
                        onSelect(bundle)
                    } label: {
                        HStack {
                            Text(bundle.name)
                                .typography(.suit16M)
                                .foregroundStyle(currentBundle?.documentId == bundle.documentId ? .gray600 : .gray400)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 10)
        }
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
            HStack(spacing: 12) {
                Text(bundleName)
                    .typography(.nanum24EB)
                    .foregroundStyle(.black100)

                if isEnabled {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .offset(y: 0.5)
                        .frame(width: 24, height: 24)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(#colorLiteral(red: 0.8861967921, green: 0.8861967921, blue: 0.8861967921, alpha: 1)), lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
