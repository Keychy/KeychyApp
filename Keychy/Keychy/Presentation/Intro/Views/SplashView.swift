//
//  SplashView.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI

// 스플래쉬 뷰
struct SplashView: View {
    var message: String = ""

    @State private var displayedMessage: String?

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Image(.introIcon)
                Image(.introTypo)
            }

            if let displayedMessage {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.gray300)
                    Text(displayedMessage)
                        .typography(.suit14M)
                        .foregroundStyle(.gray300)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .padding(.top, 12)
                    .padding(.bottom, 80)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray800)
        .task(id: message) {
            guard !message.isEmpty else { return }
            displayedMessage = nil

            let messages = [
                (delay: 2.0, text: message),
                (delay: 8.0, text: "조금만 기다려주세요\n키치가 열심히 준비 중이에요"),
                (delay: 10.0, text: "거의 다 됐어요!"),
            ]

            for step in messages {
                try? await Task.sleep(for: .seconds(step.delay))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    displayedMessage = step.text
                }
            }
        }
    }
}
