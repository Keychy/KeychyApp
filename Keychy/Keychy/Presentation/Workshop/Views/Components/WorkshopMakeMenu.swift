//
//  WorkshopMakeMenu.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI

struct WorkshopMakeMenu: View {
    let position: CGRect
    let onKeyring: () -> Void
    let onBundle: () -> Void

    private let menuWidth: CGFloat = 132
    private let menuHeight: CGFloat = 115

    @State private var isAppearing = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading, spacing: 25) {
                    // 키링 버튼
                    Button(action: onKeyring) {
                        HStack(spacing: 8) {
                            Image(.keyringMenuIcon)

                            Text("키링")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 뭉치 버튼
                    Button(action: onBundle) {
                        HStack(spacing: 8) {
                            Image(.bundleMenuIcon)
                            
                            Text("뭉치")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(width: menuWidth, height: menuHeight)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
                .scaleEffect(isAppearing ? 1.0 : 0.8, anchor: .topTrailing)
                .opacity(isAppearing ? 1.0 : 0.0)
                .position(
                    x: geometry.size.width - menuWidth / 2 - 16,
                    y: geometry.safeAreaInsets.top + menuHeight / 2 - 5 // (맨 뒤에 상수값을 조정해서 위치 조정 가능)
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
}
