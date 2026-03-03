//
//  WidgetPopup.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-03.
//

import SwiftUI

// 위젯 목록에서 삭제 확인 팝업
struct WidgetRemovePopup: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            // 아이콘
            Image(.deleteAlertPurple)
                .padding(.top, 8)

            // 제목
            Text("위젯 목록에서 삭제할까요?")
                .typography(.suit20B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)

            // 메시지
            Text("홈 화면에 추가된 위젯도 함께 삭제됩니다.")
                .typography(.suit15R)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

            // 버튼
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Text("취소")
                        .typography(.suit17SB)
                        .foregroundColor(.black100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.black10)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    Text("확인")
                        .typography(.suit17B)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.main500)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300)
    }
}

// 위젯 목록에서 삭제 완료 토스트
struct WidgetRemovedToast: View {
    @Binding var isPresented: Bool

    var body: some View {
        Text("삭제 되었습니다")
            .typography(.suit17SB)
            .foregroundColor(.black100)
            .frame(width: 300, height: 73)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            }
    }
}

// 위젯 목록에 추가 완료 토스트
struct WidgetAddedToast: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("위젯 목록에 추가되었습니다")
                .typography(.suit17SB)
                .foregroundColor(.black100)
            Text("홈 화면에서 위젯을 설정해보세요.")
                .typography(.suit15R)
                .foregroundColor(.black100)
        }
        .frame(width: 300, height: 73)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }
        }
    }
}
