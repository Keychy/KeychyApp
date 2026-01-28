//
//  CopyTooltipView.swift
//  Keychy
//
//  Created by Jini on 1/28/26.
//

import SwiftUI

// 툴팁 말풍선 View
struct CopyTooltipView: View {
    
    @State private var isAppearing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 삼각형 (위쪽 꼬리)
            Triangle()
                .fill(Color.white100)
                .frame(width: 36, height: 15)
                .offset(x: 82, y: 2)
            
            // 말풍선 내용
            Text("내가 만든 키링만 복사할 수 있어요.")
                .typography(.suit15SB25)
                .foregroundColor(.black100)
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .background(.white100)
                .cornerRadius(13)
        }
        .frame(width: 235, height: 45)
        .compositingGroup()
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 3)
        .scaleEffect(isAppearing ? 1.0 : 0.8, anchor: .top)
        .opacity(isAppearing ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
}

// 삼각형 Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    CopyTooltipView()
}
