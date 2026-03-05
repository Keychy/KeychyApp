//
//  AnimatedKeyringView.swift
//  Keychy
//
//  Created by 길지훈 on 2025-03-05.
//

import SwiftUI
import UIKit
import ClockHandRotationEffect

// MARK: - Arc 마스크 Shape

/// 큰 반지름의 호(arc)를 그려서 마스크로 사용하는 Shape
///
/// 반지름이 뷰 크기 대비 충분히 크면 호의 곡률이 0에 수렴하여
/// 위젯 크기에서는 직선처럼 동작한다.
struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double
    let radius: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path
    }
}

// MARK: - 애니메이션 키링 뷰

/// Arc Mask + clockHandRotationEffect 기반 위젯 프레임 애니메이션
///
/// 투명 배경에서도 잔상(ghosting) 불가 — 한 시점에 1개 프레임만 뷰포트에 존재.
struct AnimatedKeyringView: View {
    let frames: [UIImage]
    let size: CGFloat
    let startDate: Date

    /// 한 사이클(전체 프레임 1회 재생) 소요 시간
    static let cycleDuration: TimeInterval = 2.0

    var body: some View {
        let arcRadius = Double(size) * 50.0
        let angle = 360.0 / Double(frames.count)

        // 위상 보정: startDate 시점에 frame[0]이 보이도록 arc 위치 역보정
        let elapsed = startDate.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Self.cycleDuration)
        let phaseOffset = (elapsed / Self.cycleDuration) * 360.0

        ZStack {
            ForEach(0..<frames.count, id: \.self) { index in
                Image(uiImage: frames[index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
                    .mask(
                        ArcShape(
                            startAngle: angle * Double(index) + phaseOffset,
                            endAngle: angle * Double(index + 1) + phaseOffset,
                            radius: arcRadius
                        )
                        .stroke(style: StrokeStyle(
                            lineWidth: Double(size) * 1.5,
                            lineCap: .butt
                        ))
                        .frame(width: size, height: size)
                        .clockHandRotationEffect(period: Self.cycleDuration)
                        .offset(y: arcRadius)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}
