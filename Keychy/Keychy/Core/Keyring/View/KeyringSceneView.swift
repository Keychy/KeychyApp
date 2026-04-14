//
//  KeyringSceneView.swift
//  KeytschPrototype
//
//  Created by rundo on 10/22/25.
//

import SwiftUI
import SpriteKit
import Lottie

/// 키링 SpriteKit Scene + 로티재생 ZStack뷰 (Generic)
struct KeyringSceneView<VM: KeyringViewModelProtocol>: View {
    @Bindable var viewModel: VM
    var screen: KeyringScale.Screen = .customizing  // 화면 종류 (zoomScale용)
    var backgroundColor: UIColor = .gray50
    var applyWelcomeImpulse: Bool = false  // 씬 준비 완료 시 자동 파티클 효과
    var onSceneReady: (() -> Void)? = nil  // 씬 준비 완료 콜백

    @Environment(\.previewScaleFactor) private var previewScale
    @State private var scene: KeyringScene? = nil
    @State private var showEffect: Bool = false
    @State private var currentEffect: String = ""
    @State private var lottieID = UUID()

    var body: some View {
        ZStack {
            sceneView
            if showEffect { lottieEffectView }
        }
        .onAppear {
            setupScene()
        }
        .onDisappear {
            // 뷰가 사라질 때 씬 정리
            cleanupScene()
        }
        .onChange(of: viewModel.bodyImage) { _, newImage in
            // bodyImage 변경 시 씬 재생성
            cleanupScene()

            // 다음 프레임에서 새 씬 생성
            DispatchQueue.main.async {
                setupScene()
            }
        }
    }

    // MARK: - Scene Cleanup

    /// 씬 정리 및 메모리 해제
    private func cleanupScene() {
        // Scene의 cleanup 메서드 호출 (물리 조인트, 콜백 등 정리)
        scene?.cleanup()

        // Scene을 nil로 설정하여 메모리 해제
        scene = nil

        // 파티클 효과 정리
        showEffect = false
        currentEffect = ""
    }

    // MARK: - Scene Setup

    private func setupScene() {
        let newScene = KeyringScene(
            ringType: .basic,
            chainType: .basic,
            templateId: viewModel.templateId,
            isGyroscope: viewModel.isGyroscope,
            screen: screen,
            bodyImage: viewModel.bodyImage,
            backgroundColor: backgroundColor,
            hookOffsetY: viewModel.hookOffsetY != 0 ? viewModel.hookOffsetY : nil,
            chainLength: viewModel.chainLength,
            previewScale: previewScale,
            hasDynamicIsland: {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = scene.windows.first else { return true }
                return window.safeAreaInsets.bottom > 0
            }()
        )
        newScene.scaleMode = .resizeFill

        // 파티클 효과 콜백 설정 (씬 생성 시 즉시 설정)
        newScene.onPlayParticleEffect = { effectName in
            DispatchQueue.main.async { [self] in
                self.currentEffect = effectName
                self.lottieID = UUID()
                self.showEffect = true
            }
        }

        // Setup 완료 콜백 설정 (Body까지 완전히 생성된 시점)
        // bind(to:) 전에 설정해야 bind가 이 콜백을 래핑하여 스타일 초기값 적용 가능
        newScene.onSetupComplete = { [weak newScene] in
            DispatchQueue.main.async {
                onSceneReady?()

                // 환영 효과: Setup 완료 후 파티클 터뜨리기
                if applyWelcomeImpulse {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        newScene?.applyWelcomeImpulse()
                    }
                }
            }
        }

        // VM 바인딩 (onSetupComplete 래핑 + styleSubject 구독)
        newScene.bind(to: viewModel)

        scene = newScene
    }
}

extension KeyringSceneView {
    /// SpriteKit Scene 표시 뷰
    /// 3D 회전은 SKTransformNode가 바디 노드 레벨에서 처리 (고리/체인 영향 없음)
    private var sceneView: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Lottie 효과 뷰
    private var lottieEffectView: some View {
        LottieView(
            name: currentEffect,
            loopMode: .playOnce,
            speed: 1.0
        )
        .id(lottieID)
        .allowsHitTesting(false)
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showEffect = false }
            }
        }
    }
}
