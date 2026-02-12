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

    @State private var isFrameLoaded: Bool = false
    
    // 크기 설정
    private let targetFrameHeight: CGFloat = 269

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메인 콘텐츠
                VStack {
                    ZStack(alignment: .top) {
                        // 프레임 + 안장 + 갈기 합성 영역
                        VStack {
                            Spacer()
                                .frame(height: 115)

                            compositionView
                        }

                        // frameChain 이미지 (위에 겹침)
                        Image(.frameChain)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                            .offset(y: 5)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 168)
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
