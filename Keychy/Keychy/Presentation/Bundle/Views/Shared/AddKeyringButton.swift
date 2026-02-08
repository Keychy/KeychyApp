//
//  AddKeyringButton.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//
/// 카라비너에 키링 달릴 위치를 표시하는 + 버튼입니다.
import SwiftUI

struct AddKeyringButton: View {
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(.plus)
                .resizable()
                .frame(width: 21.48, height: 21.48)
        }
        .frame(width: 30, height: 30)
        .glassEffect(.clear.interactive(), in: .circle)
    }
}
