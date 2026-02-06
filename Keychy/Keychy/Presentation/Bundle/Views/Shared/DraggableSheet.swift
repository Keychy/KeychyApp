//
//  DraggableSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI

struct DraggableSheet<Content: View>: View {
    @Binding var sheetHeight: CGFloat
    let content: Content
    var onDismiss: (() -> Void)? = nil

    // 화면 높이 기준 비율
    private let dismissRatio: CGFloat = 0.15
    private let mediumRatio: CGFloat = 0.40
    private let largeRatio: CGFloat = 0.80
    
    // 계산된 높이 값들
    private var dismissHeight: CGFloat {
        screenHeight * dismissRatio
    }

    private var mediumHeight: CGFloat {
        screenHeight * mediumRatio
    }

    private var largeHeight: CGFloat {
        screenHeight * largeRatio
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // 인디케이터
            VStack(spacing:0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.gray300)
                    .frame(width: 36, height: 5)
                    .padding(6)
                Text("선택")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)
                    .padding(EdgeInsets(top: 14, leading: 0, bottom: 12, trailing: 0))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture)
            
            ScrollView {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .scrollContentBackground(.hidden)
            .safeAreaPadding(.top, 0) // ScrollView 상단 패딩 제거
            .gesture(dragGesture)
        }
        .frame(height: sheetHeight)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .stroke(.gray50, lineWidth: 1)
                .shadow(color: .black15, radius: 9, x: 0, y: 0)
        )
        .glassEffect(.regular, in: .rect)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .onAppear {
            sheetHeight = mediumHeight
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let newHeight = sheetHeight - value.translation.height
                // 0 이상, largeHeight 이하까지 드래그 가능
                if newHeight >= 0 && newHeight <= largeHeight {
                    sheetHeight = newHeight
                }
            }
            .onEnded { _ in
                // 내리면 닫기 (거의 끝까지 내려야 닫힘)
                let dismissThreshold = dismissHeight + (mediumHeight - dismissHeight) * 0.05
                let midMediumLarge = (mediumHeight + largeHeight) / 2

                if sheetHeight < dismissThreshold {
                    // dismiss는 호출하는 쪽에서 애니메이션 제어
                    onDismiss?()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if sheetHeight < midMediumLarge {
                            sheetHeight = mediumHeight
                        } else {
                            sheetHeight = largeHeight
                        }
                    }
                }
            }
    }
}

