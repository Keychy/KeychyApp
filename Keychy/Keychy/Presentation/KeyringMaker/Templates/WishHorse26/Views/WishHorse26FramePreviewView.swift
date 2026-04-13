//
//  WishHorse26FramePreviewView.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI
import NukeUI

struct WishHorse26FramePreviewView: View {
    @Bindable var viewModel: WishHorse26VM
    let onSceneReady: () -> Void

    @Environment(\.previewScaleFactor) private var previewScale
    @Environment(\.previewTopPadding) private var topPadding
    @State private var isFrameLoaded: Bool = false

    // 크기 설정 (previewScale 적용)
    private var targetFrameHeight: CGFloat { 269 * previewScale }
    
    // MARK: - 프레임 타입에 따른 변환 여부
    private var shouldApplyTransform: Bool {
        guard let frame = viewModel.selectedFrame else {
            return false
        }
        // type이 "A"인 경우 변환 적용
        return frame.type == "A"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메인 콘텐츠
                VStack {
                    ZStack(alignment: .top) {
                        // 프레임 + 안장 + 갈기 합성 영역
                        VStack {
                            Spacer()
                                .frame(height: 115 * previewScale)

                            compositionView
                                .offset(y: -3)
                        }

                        // frameChain 이미지 (위에 겹침)
                        Image(.frameChain)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90 * previewScale)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, topPadding)
                .opacity(isFrameLoaded ? 1 : 0)

                // 로딩 중일 때
                if !isFrameLoaded {
                    LoadingAlert(type: .short40, message: nil)
                }
            }
        }
        .onAppear {
            // 일반 SwiftUI View는 즉시 준비 완료
            onSceneReady()
        }
        .onChange(of: viewModel.selectedFrame) { _, _ in
            Task {
                await viewModel.composeHorse()
            }
        }
        .onChange(of: viewModel.selectedSaddle) { _, _ in
            Task {
                await viewModel.composeHorse()
            }
        }
        .onChange(of: viewModel.selectedMane) { _, _ in
            Task {
                await viewModel.composeHorse()
            }
        }
    }
    
    @ViewBuilder
    private var compositionView: some View {
        ZStack(alignment: .center) {
            if let frame = viewModel.selectedFrame {
                LazyImage(url: URL(string: frame.frameURL)) { state in
                    if let image = state.image {
                        ZStack(alignment: .center) {
                            // 1. 프레임 이미지 (원본 크기)
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: targetFrameHeight)
                            
                            // 2. 갈기 이미지
                            if let mane = viewModel.selectedMane {
                                LazyImage(url: URL(string: mane.imageURL)) { maneState in
                                    if let maneImage = maneState.image {
                                        maneImage
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: targetFrameHeight)
                                    }
                                }
                            }

                            // 2. 안장 이미지
                            if let saddle = viewModel.selectedSaddle {
                                LazyImage(url: URL(string: saddle.imageURL)) { saddleState in
                                    if let saddleImage = saddleState.image {
                                        saddleImage
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: targetFrameHeight)
                                    }
                                }
                            }
                        }
                        // MARK: - type "A"일 때만 변환 적용
                        .rotationEffect(.degrees(shouldApplyTransform ? 20 : 0))
                        .offset(
                            x: shouldApplyTransform ? 15.39 * previewScale : -0.1,
                            y: shouldApplyTransform ? 37.34 * previewScale : 0
                        )
                        .onAppear {
                            isFrameLoaded = true
                        }
                    }
                }
                .onDisappear {
                    isFrameLoaded = false
                }
            }
        }
    }
}
