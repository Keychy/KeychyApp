//
//  CrossStitchSizeSelection.swift
//  Keychy
//
//  Created by Jini on 3/10/26.
//

import SwiftUI
import NukeUI

enum CrossStitchGridSize: Int, CaseIterable {
    case small = 16
    case medium = 24
    case large = 32

    var label: String { "\(rawValue) x \(rawValue)" }

    var previewImage: ImageResource {
        switch self {
        case .small:  return .crossStitch16
        case .medium: return .crossStitch24
        case .large:  return .crossStitch32
        }
    }
}

struct CrossStitchSizeSelection: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (CrossStitchGridSize) -> Void

    @State private var selectedSize: CrossStitchGridSize = .small
    @State private var contentHeight = 400

    var body: some View {
        VStack(spacing: 0) {
            // 상단 닫기 버튼
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(.dismissGray600)
                }
                .padding(.top, 30)
                .padding(.leading, 20)
                Spacer()
            }
            .padding(.bottom, 19.5)
            
            Text("도안 크기를 선택해주세요")
                .typography(.suit20B)
                .foregroundStyle(.gray600)
                .padding(.bottom, 28)
            
            // 3가지 사이즈 카드
            HStack(spacing: 10) {
                ForEach(CrossStitchGridSize.allCases, id: \.rawValue) { size in
                    CrossStitchGridSizeCard(
                        size: size,
                        isSelected: selectedSize == size
                    ) {
                        selectedSize = size
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 30)
            
            createButton
                .adaptiveBottomPadding()
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: GuidingHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        )
        .background(Color.white100)
        .presentationBackground(Color.white100)
        .presentationDetents([.height(CGFloat(contentHeight))])
    }
}

// MARK: - Components
extension CrossStitchSizeSelection {
    private var createButton: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSelect(selectedSize)
            }
        } label: {
            Text("만들기")
                .typography(.suit17B)
                .foregroundStyle(.white100)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .padding(.horizontal, 26)
        .buttonStyle(.glassProminent)
        .tint(.main500)
    }
}

// MARK: - Size Card
struct CrossStitchGridSizeCard: View {
    let size: CrossStitchGridSize
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Image(size.previewImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isSelected ? Color.main500 : Color.clear,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                Text(size.label)
                    .typography(.notosans15M)
                    .foregroundStyle(.black100)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white100)

        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
