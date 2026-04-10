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

    // 뷰 로컬 상태 (MVVM: 포커스는 뷰 책임)
    @FocusState private var focusedField: UniformField?
    @State private var isFrameLoaded: Bool = false

    enum UniformField {
        case number
        case playerName
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    ZStack(alignment: .top) {
                        VStack {
                            Spacer()
                                .frame(height: 119)

                            compositionView
                        }

                        // 체인 이미지 (위에 겹침)
                        Image(.frameChain2)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                            .offset(y: -40)
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
        .dismissKeyboardOnTap()
        .onAppear {
            onSceneReady()
        }
    }

    // MARK: - Composition View

    @ViewBuilder
    private var compositionView: some View {
        ZStack(alignment: .center) {
            if let frame = viewModel.selectedFrame {
                LazyImage(url: URL(string: frame.frameURL)) { state in
                    if let image = state.image {
                        ZStack(alignment: .center) {
                            // 1. 유니폼 프레임 이미지
                            image
                                .resizable()
                                .scaledToFit()

                            // 2. 등번호 + 이름 오버레이
                            uniformTextOverlay(frame: frame)
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

    // MARK: - Uniform Text Overlay

    @ViewBuilder
    private func uniformTextOverlay(frame: Frame) -> some View {
        let numberOffsetY = frame.numberOffsetY ?? -20
        let nameOffsetY = frame.nameOffsetY ?? 40

        VStack(spacing: 0) {
            // 등번호 영역
            ZStack {
                if viewModel.numberText.isEmpty {
                    Text("00")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.gray300.opacity(0.5))
                }

                TextField("", text: $viewModel.numberText)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(viewModel.numberInnerColor)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .number)
                    .onChange(of: viewModel.numberText) { _, newValue in
                        // 숫자만 허용, 0~99 (2자리) 제한
                        let filtered = String(newValue.filter { $0.isNumber }.prefix(2))
                        if filtered != newValue {
                            viewModel.numberText = filtered
                        }
                    }
            }
            .frame(height: 50)
            .offset(y: numberOffsetY)
            .onTapGesture {
                focusedField = .number
            }

            // 이름 영역
            ZStack {
                if viewModel.playerNameText.isEmpty {
                    Text("이름")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.gray300.opacity(0.5))
                }

                TextField("", text: $viewModel.playerNameText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(viewModel.nameInnerColor)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .playerName)
                    .onChange(of: viewModel.playerNameText) { _, newValue in
                        // 8자 제한
                        if newValue.count > 8 {
                            viewModel.playerNameText = String(newValue.prefix(8))
                        }
                    }
            }
            .frame(height: 30)
            .offset(y: nameOffsetY)
            .onTapGesture {
                focusedField = .playerName
            }
        }
        .padding(.horizontal, 40)
    }
}
