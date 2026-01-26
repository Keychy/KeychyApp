//
//  WorkshopBundleBanner.swift
//  Keychy
//
//  Created by 길지훈 on 1/25/26.
//

import SwiftUI
import Combine

/// 번들 탭 배너 - 1초마다 이미지 전환
struct WorkshopBundleBanner: View {
    @State private var currentIndex = 0

    private let images: [ImageResource] = [
        .bundleBanner1,
        .bundleBanner2,
        .bundleBanner3,
        .bundleBanner4
    ]

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Image(images[currentIndex])
            .resizable()
            .aspectRatio(contentMode: .fit)
            .onReceive(timer) { _ in
                currentIndex = (currentIndex + 1) % images.count
            }
            .padding(.horizontal, 8.5)
    }
}
