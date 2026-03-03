//
//  KeyringMenu.swift
//  Keychy
//
//  Created by Jini on 11/5/25.
//

import SwiftUI

struct KeyringMenu: View {
    let position: CGRect
    let isMyKeyring: Bool
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onWidget: () -> Void
    let onWidgetAdd: () -> Void
    let isWidgetAdded: Bool
    
    private let menuWidth: CGFloat = 225
    private let menuHeight: CGFloat = 271.25
    
    @State private var isAppearing = false
    @State private var showCopyTooltip = false
    @State private var questionButtonFrame: CGRect = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메뉴
                menuContent
                    .position(
                        x: geometry.size.width - menuWidth / 2 - 16,
                        y: position.maxY + 16 + menuHeight / 2
                    )
                
                // 툴팁 말풍선
                if showCopyTooltip {
                    CopyTooltipView()
                        .position(
                            x: geometry.size.width - 125,
                            y: questionButtonFrame.maxY + 32
                        )
                        .zIndex(1000)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
        // 툴팁 외부 클릭 시 닫기
        .onTapGesture {
            if showCopyTooltip {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showCopyTooltip = false
                }
            }
        }
    }
    
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 편집 버튼
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image(.pencil)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.gray600)
                    
                    Text("정보 수정")
                        .typography(.suit16M)
                        .foregroundColor(.gray600)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 복사 버튼
            HStack(spacing: 8) {
                Image(.copy)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .foregroundColor(isMyKeyring ? .gray600 : .gray300)
                
                Text("복사")
                    .typography(.suit16M)
                    .foregroundColor(isMyKeyring ? .gray600 : .gray300)
                
                Spacer()
                
                if !isMyKeyring {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showCopyTooltip.toggle()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.gray500)
                                .frame(width: 15, height: 15)
                            
                            Text("?")
                                .typography(.nanum12EB)
                                .foregroundColor(.white)
                        }
                    }
                    // 물음표 버튼의 위치 추적
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: QuestionButtonPreferenceKey.self,
                                    value: geo.frame(in: .global)
                                )
                        }
                    )
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                if isMyKeyring {
                    onCopy()
                }
            }
            
            // 삭제 버튼
            Button(action: onDelete) {
                HStack(spacing: 8) {
                    Image(.trash)
                        .resizable()
                        .frame(width: 25, height: 25)
                    
                    Text("삭제")
                        .typography(.suit16M)
                        .foregroundColor(.pink)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 구분선
            Rectangle()
                .fill(Color.gray100)
                .padding(.horizontal, 10)
                .frame(height: 1)
            
            // 위젯 튜토리얼 버튼
            Button(action: onWidget) {
                HStack(spacing: 8) {
                    Image(.widget)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray600)
                    
                    Text("위젯 튜토리얼")
                        .typography(.suit16M)
                        .foregroundColor(.gray600)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 위젯에 추가/제거 버튼
            Button(action: onWidgetAdd) {
                HStack(spacing: 8) {
                    Image(.pinButtonGray600)
                        .resizable()
                        .frame(width: 26, height: 26)

                    Text("위젯 목록에 추가")
                        .typography(.suit16M)

                    Text("추가됨")
                        .typography(.suit11M)
                        .foregroundStyle(.main500)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.black10)
                        )
                        .opacity(isWidgetAdded ? 1 : 0)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 20)
        .frame(width: menuWidth, height: menuHeight)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .scaleEffect(isAppearing ? 1.0 : 0.8, anchor: .topTrailing)
        .opacity(isAppearing ? 1.0 : 0.0)
        .onPreferenceChange(QuestionButtonPreferenceKey.self) { frame in
            questionButtonFrame = frame
        }
    }
}

// 물음표 버튼 위치 추적용 PreferenceKey
struct QuestionButtonPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
