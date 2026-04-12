//
//  UniformFramePreviewView.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//
//  유니폼 프레임 위에 등번호/이름 TextField 오버레이 (핵심 뷰)
//

import SwiftUI
import NukeUI
import Nuke

struct UniformFramePreviewView: View {
    @Bindable var viewModel: UniformVM
    let onSceneReady: () -> Void

    @State private var isFrameLoaded: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    ZStack(alignment: .top) {
                        VStack {
                            Spacer()
                                .frame(height: 135)

                            compositionView
                                .offset(x: 1)
                        }

                        // 체인 이미지 (위에 겹침)
                        Image(.frameChain)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 168)
                .opacity(isFrameLoaded ? 1 : 0)

                if !isFrameLoaded {
                    LoadingAlert(type: .short40, message: nil)
                }
            }
        }
        .onAppear {
            onSceneReady()
        }
    }

    // MARK: - Composition View

    @ViewBuilder
    private var compositionView: some View {
        ZStack(alignment: .center) {
            if let frame = viewModel.selectedFrame {
                let uniformType = frame.uniformType ?? "base"

                // 아크릴이 전체 크기를 결정하고, 나머지는 그 위에 정렬
                ZStack {
                    // 1. 아크릴 (입체감/그림자) — ZStack 크기 기준
                    Image("\(uniformType)_arcylic")
                        .resizable()
                        .frame(width: 302.03, height: 254.16)
                        .offset(y: -0.5)

                    // 2~5: 유니폼 레이어 (고정 크기로 아크릴 위에 정렬)
                    let layerSize = CGSize(width: 280, height: 205.5)

                    Group {
                        // 2. Color2 + base mask (베이스 영역)
                        Rectangle()
                            .fill(viewModel.uniformColor2)
                            .mask {
                                Image("\(uniformType)_base")
                                    .resizable()
                                    .scaledToFit()
                            }

                        // 3. Color1 + pattern mask (Firebase 패턴)
                        LazyImage(url: URL(string: frame.frameURL)) { state in
                            if let image = state.image {
                                Rectangle()
                                    .fill(viewModel.uniformColor1)
                                    .mask {
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .onAppear {
                                        isFrameLoaded = true
                                    }
                            }
                        }

                        // 4. stroke (외곽선)
                        Image("\(uniformType)_stroke")
                            .resizable()
                            .scaledToFit()

                        // 5. 텍스트 오버레이 (등번호 + 이름)
                        uniformTextOverlay(frame: frame)
                    }
                    .frame(width: layerSize.width, height: layerSize.height)
                    .offset(y: 14.5)
                    .offset(x: -2)
                }
                .onDisappear {
                    isFrameLoaded = false
                }
            }
        }
    }

    // MARK: - Uniform Text Overlay (읽기 전용 — 입력은 마킹 탭에서)

    @ViewBuilder
    private func uniformTextOverlay(frame: Frame) -> some View {
        let numberOffsetY = frame.numberOffsetY ?? -20
        let nameOffsetY = frame.nameOffsetY ?? 40

        VStack(spacing: 0) {
            // 등번호 표시
            if !viewModel.numberText.isEmpty {
                Text(viewModel.numberText)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(viewModel.numberInnerColor)
            }
        }
        .offset(y: numberOffsetY)

        VStack(spacing: 0) {
            // 이름 표시
            if !viewModel.playerNameText.isEmpty {
                Text(viewModel.playerNameText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(viewModel.nameInnerColor)
            }
        }
        .offset(y: nameOffsetY)
    }
}
