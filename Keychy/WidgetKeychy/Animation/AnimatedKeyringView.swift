//
//  AnimatedKeyringView.swift
//  Keychy
//
//  Created by 길지훈 on 2025-03-05.
//

import SwiftUI
import UIKit
import WidgetKit

// MARK: - 애니메이션 설정

enum AnimationConfig {
    static let frameCount = AnimationFrameStorage.frameCount  // 30
    static let halfCount = frameCount / 2  // 15

    /// 15 FPS (30프레임, 각 프레임 ≈0.067초)
    static let fps: CGFloat = 15.0
    static let frameDuration: CGFloat = 1.0 / fps

    /// 타이머 최대 자릿수 (H:MM:SS 등)
    static let maxDigitSlots: CGFloat = 9
}

// MARK: - BlinkMask 마스크 뷰

/// BlinkMask 폰트로 1초 on/off 깜빡이는 마스크
///
/// BlinkMask 폰트 구조:
/// - 짝수 숫자(0,2,4,6,8) → 불투명 사각형 (보임)
/// - 홀수 숫자(1,3,5,7,9) → 투명 (안 보임)
///
/// `blinkOffset`으로 타이머 기준 시점을 이동시켜
/// 각 프레임이 서로 다른 타이밍에 보이도록 제어한다.
struct SimpleBlinkingView: View {
    let referenceDate: Date
    let blinkOffset: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            let maxSize = max(geometry.size.width, geometry.size.height)

            Text(referenceDate.addingTimeInterval(-blinkOffset), style: .timer)
                .font(.custom("BlinkMask", size: maxSize))
                .centerLastCharacter(size: maxSize, anchor: .topLeading)
        }
        .clipped()
    }
}

// MARK: - 애니메이션 키링 뷰

/// BlinkMask + 다중 타이머 오프셋으로 15 FPS 프레임 애니메이션을 구현
///
/// **동작 원리**:
/// 30개 프레임에 각각 다른 타이머 오프셋(0, 1/15, 2/15, ...)을 적용.
/// BlinkMask 폰트가 짝수초/홀수초마다 on/off되므로,
/// 오프셋이 다른 프레임은 미세하게 다른 타이밍에 깜빡인다.
/// 결과적으로 30개 프레임이 순차적으로 표시되어 애니메이션이 된다.
///
/// **반분할(Half) 구조**:
/// - 전반부 (Frame 0~14): 각 프레임이 개별 마스크로 순차 표시
/// - 후반부 (Frame 15~29): 추가 1초 블링크 마스크로 전반부와 교대
///
/// ⚠️ 투명 배경에서는 여러 프레임이 동시에 보여 잔상(ghosting) 발생.
/// 불투명 배경에서는 최상위 프레임이 하위를 가려 정상 동작.
struct AnimatedKeyringView: View {
    let frames: [UIImage]
    let size: CGFloat
    let referenceDate: Date

    var body: some View {
        ZStack {
            // 전반부 (Frame 0~14)
            // Frame 0: 마스크 없음 (루프 전환 시 빈 화면 방지용 폴백)
            ZStack {
                imageFrame(index: 0, masked: false)

                ForEach(1..<AnimationConfig.halfCount, id: \.self) { i in
                    imageFrame(index: i)
                }
            }

            // 후반부 (Frame 15~29): 1초 블링크로 전반부와 번갈아 표시
            ZStack {
                ForEach(
                    AnimationConfig.halfCount..<min(frames.count, AnimationConfig.frameCount),
                    id: \.self
                ) { i in
                    imageFrame(index: i)
                }
            }
            .mask(
                SimpleBlinkingView(referenceDate: referenceDate, blinkOffset: 1)
                    .frame(width: size, height: size)
            )
        }
        .frame(width: size, height: size)
    }

    /// 개별 프레임 뷰 (타이머 오프셋 기반 마스크 적용)
    @ViewBuilder
    private func imageFrame(index: Int, masked: Bool = true) -> some View {
        let base = Image(uiImage: frames[index])
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipped()

        if masked {
            base.mask(
                SimpleBlinkingView(
                    referenceDate: referenceDate,
                    blinkOffset: CGFloat(-index) * AnimationConfig.frameDuration
                )
                .frame(width: size, height: size)
            )
        } else {
            base
        }
    }
}

// MARK: - Text 센터링 확장

extension Text {
    /// 타이머 마지막 글자를 뷰의 특정 위치에 배치
    ///
    /// 타이머 텍스트("0:00" 등)의 마지막 자릿수만 보이도록
    /// 큰 프레임으로 확장 후 오프셋으로 위치 조정
    enum AnchorOrigin {
        case viewCenter
        case topLeading
    }

    func centerLastCharacter(size: CGFloat, anchor: AnchorOrigin = .viewCenter) -> some View {
        let multiplier: CGFloat = switch anchor {
        case .viewCenter: (AnimationConfig.maxDigitSlots - 1) / 2
        case .topLeading: AnimationConfig.maxDigitSlots - 1
        }
        return self
            .frame(width: size * AnimationConfig.maxDigitSlots, height: size)
            .multilineTextAlignment(.trailing)
            .offset(x: -size * multiplier)
    }
}
