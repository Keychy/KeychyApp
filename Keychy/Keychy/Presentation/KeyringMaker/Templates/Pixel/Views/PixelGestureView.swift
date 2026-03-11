//
//  PixelGestureView.swift
//  Keychy
//
//  Created by Jini on 3/10/26.
//

import SwiftUI

struct PixelGestureView: UIViewRepresentable {
    let onDraw: (CGPoint) -> Void        // 한 손가락 드래그 + 탭
    let onPan: (CGSize) -> Void          // 두 손가락 드래그
    let onPanEnd: () -> Void
    let onPinch: (CGFloat) -> Void       // 핀치
    let onPinchEnd: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        // 한 손가락 드래그 (그리기)
        let drawPan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDraw(_:))
        )
        drawPan.maximumNumberOfTouches = 1
        drawPan.delegate = context.coordinator
        view.addGestureRecognizer(drawPan)

        // 두 손가락 드래그 (패닝)
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.minimumNumberOfTouches = 2
        panGesture.maximumNumberOfTouches = 2
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)

        // 핀치 (확대/축소)
        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinch.delegate = context.coordinator
        view.addGestureRecognizer(pinch)

        // 싱글탭 (그리기)
        let singleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSingleTap(_:))
        )
        singleTap.numberOfTapsRequired = 1
        singleTap.delegate = context.coordinator
        view.addGestureRecognizer(singleTap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onDraw: onDraw,
            onPan: onPan,
            onPanEnd: onPanEnd,
            onPinch: onPinch,
            onPinchEnd: onPinchEnd
        )
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onDraw: (CGPoint) -> Void
        let onPan: (CGSize) -> Void
        let onPanEnd: () -> Void
        let onPinch: (CGFloat) -> Void
        let onPinchEnd: () -> Void

        init(
            onDraw: @escaping (CGPoint) -> Void,
            onPan: @escaping (CGSize) -> Void,
            onPanEnd: @escaping () -> Void,
            onPinch: @escaping (CGFloat) -> Void,
            onPinchEnd: @escaping () -> Void
        ) {
            self.onDraw = onDraw
            self.onPan = onPan
            self.onPanEnd = onPanEnd
            self.onPinch = onPinch
            self.onPinchEnd = onPinchEnd
        }

        // 싱글탭 → 그리기
        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            onDraw(point)
        }

        // 한 손가락 드래그 → 그리기
        @objc func handleDraw(_ gesture: UIPanGestureRecognizer) {
            guard gesture.numberOfTouches == 1 else { return }
            guard gesture.state == .began || gesture.state == .changed else { return }
            let point = gesture.location(in: gesture.view)
            onDraw(point)
        }

        // 두 손가락 드래그 → 패닝
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            switch gesture.state {
            case .changed:
                onPan(CGSize(width: translation.x, height: translation.y))
            case .ended, .cancelled:
                onPanEnd()
            default:
                break
            }
        }

        // 핀치 → 확대/축소
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .changed:
                onPinch(gesture.scale)
                gesture.scale = 1.0
            case .ended, .cancelled:
                onPinchEnd()
            default:
                break
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}
