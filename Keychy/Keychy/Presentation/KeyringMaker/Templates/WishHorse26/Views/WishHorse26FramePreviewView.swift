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

    @FocusState private var isTextFieldFocused: Bool
    @State private var isFrameLoaded: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메인 콘텐츠
                VStack {
                    ZStack(alignment: .top) {
                        // 프레임 + 텍스트 영역
                        VStack {
                            Spacer()
                                .frame(height: 95)  // 126 → 95

                            compositionView
                        }

                        // frameChain 이미지 (위에 겹침)
                        Image(.frameChain)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                            .offset(y: -31)
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
        .dismissKeyboardOnTap()
        .onAppear {
            // 일반 SwiftUI View는 즉시 준비 완료
            onSceneReady()
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

                            // 2. 텍스트 입력 필드 (중앙에 오버레이)
                            //textInputField
                                .offset(y: frame.textOffsetY ?? 0)
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
