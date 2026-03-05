//
//  AnimatedKeyringView.swift
//  Keychy
//
//  Created by 길지훈 on 2025-03-05.
//

import SwiftUI
import WidgetKit

// MARK: - 애니메이션 설정

enum AnimationConfig {
    static let frameCount = AnimationFrameStorage.frameCount  // 30
    static let halfCount = frameCount / 2                     // 15

    /// 15 FPS — 키링 흔들림 애니메이션에 충분한 프레임 레이트
    static let fps: CGFloat = 15.0
    static let frameDuration: CGFloat = 1.0 / fps

    /// BlinkMask 타이머의 기준 시각 오프셋
    /// 타이머가 0:00에 리셋되므로, 모든 오프셋이 양수가 되도록
    /// 충분히 과거 시점을 기준으로 잡는다.
    static let referenceOffset: TimeInterval = 60

    /// 타이머가 표시할 수 있는 최대 자릿수 (H:MM:SS + 소수점)
    /// 마지막 글자 센터링에 사용
    static let maxDigitSlots: CGFloat = 9
}

// MARK: - 애니메이션 키링 뷰

/// BlinkMask 폰트 기법으로 30프레임 키링 애니메이션을 표시하는 뷰
///
/// 원리: WidgetKit은 프레임 애니메이션을 직접 지원하지 않지만,
/// `Text(.timer)`는 매초 업데이트된다. BlinkMask 폰트는 짝수 숫자 = 불투명 사각형,
/// 홀수 숫자 = 투명으로 구성되어 있어서 프로그래밍 가능한 마스크 역할을 한다.
///
/// 30프레임을 두 그룹(0~14, 15~29)으로 나누어:
/// 1) 전반부(0~14)는 항상 화면에 표시되며, 각 프레임은 1/15초간만 보임
/// 2) 후반부(15~29)는 1초 주기 깜빡임 마스크로 전반부와 번갈아 표시
struct AnimatedKeyringView: View {
    let frames: [UIImage]
    let size: CGFloat

    /// 모든 타이머가 동기화되도록 같은 기준 시각을 공유
    static let referenceDate = Date() - AnimationConfig.referenceOffset

    var body: some View {
        ZStack {
            // 전반부 (0~14): 항상 화면에 표시
            // 프레임 0은 마스크 없음 — 루프 전환 시 흰색 깜빡임 방지용 폴백
            ZStack {
                imageFrame(image: frames[0], index: 0, masked: false)

                ForEach(1..<AnimationConfig.halfCount, id: \.self) { i in
                    imageFrame(image: frames[i], index: i)
                }
            }

            // 후반부 (15~29): 1초 주기 깜빡임 마스크 적용
            ZStack {
                ForEach(AnimationConfig.halfCount..<AnimationConfig.frameCount, id: \.self) { i in
                    imageFrame(image: frames[i], index: i)
                }
            }
            .mask(
                SimpleBlinkingView(blinkOffset: 1)
                    .frame(width: size, height: size)
            )
        }
        .frame(width: size, height: size)
    }

    /// 개별 프레임 뷰 — 각 프레임은 자신의 타임 슬롯에서만 보이도록 마스킹됨
    @ViewBuilder
    private func imageFrame(image: UIImage, index: Int, masked: Bool = true) -> some View {
        let base = Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipped()

        if masked {
            base.mask(
                SimpleBlinkingView(blinkOffset: CGFloat(-index) * AnimationConfig.frameDuration)
                    .frame(width: size, height: size)
            )
        } else {
            base
        }
    }
}

// MARK: - BlinkMask 깜빡임 뷰

/// BlinkMask 커스텀 폰트로 깜빡이는 마스크 뷰
///
/// BlinkMask 폰트는 짝수 숫자 = 불투명 사각형, 홀수 = 투명.
/// `Text(.timer)`의 마지막 자릿수가 0~9를 순환하면서
/// 1초 켜짐 / 1초 꺼짐을 반복하는 마스크가 된다.
///
/// `blinkOffset`으로 타이머 기준 시각을 이동시켜
/// 각 프레임이 정확한 시점에 보이도록 제어한다.
struct SimpleBlinkingView: View {
    var blinkOffset: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            let maxSize = max(geometry.size.width, geometry.size.height)

            Text(AnimatedKeyringView.referenceDate - blinkOffset, style: .timer)
                .font(.custom("BlinkMask", size: maxSize))
                .centerLastCharacter(size: maxSize, anchor: .topLeading)
        }
        .clipped()
    }
}

// MARK: - Text 센터링 확장

extension Text {
    /// 타이머 마지막 글자를 뷰 중앙에 배치하는 트릭
    ///
    /// 1) 너비를 size×9로 설정 (타이머 최대 9자리 수용)
    /// 2) trailing 정렬로 마지막 자릿수를 오른쪽 끝에 고정
    /// 3) 오프셋으로 오른쪽 끝이 뷰 중앙에 오도록 이동
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
