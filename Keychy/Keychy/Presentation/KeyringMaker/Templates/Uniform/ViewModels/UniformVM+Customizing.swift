//
//  UniformVM+Customizing.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//

import SwiftUI

extension UniformVM {

    // MARK: - Lifecycle Callbacks

    func onModeChanged(from oldMode: CustomizingMode, to newMode: CustomizingMode) {
        // 프레임/마킹 탭에서 벗어날 때 합성 수행
        if (oldMode == .frame || oldMode == .marking) && newMode == .effect {
            Task {
                await composeUniformWithText()
            }
        }
    }

    func beforeNavigateToNext() {
        Task {
            await composeUniformWithText()
        }
    }

    // MARK: - Scene View Provider

    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
        case .frame:
            return AnyView(UniformCompositionView(viewModel: self, onSceneReady: onSceneReady))
        case .marking:
            // 마킹 탭에서도 유니폼 프리뷰 표시 (색상 변경 실시간 반영)
            return AnyView(UniformCompositionView(viewModel: self, onSceneReady: onSceneReady))
        default:
            return AnyView(EmptyView())
        }
    }

    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(EffectSelectorView(viewModel: self, cartItems: cartItems))
        case .frame:
            return AnyView(UniformFrameTabView(viewModel: self, cartItems: cartItems))
        case .marking:
            return AnyView(UniformMarkingTabView(viewModel: self))
        default:
            return AnyView(EmptyView())
        }
    }

    func bottomViewHeightRatio(for mode: CustomizingMode) -> CGFloat {
        switch mode {
        case .frame:
            return 0.38
        case .marking:
            return 0.45
        case .effect:
            return 0.35
        default:
            return 0.35
        }
    }
}
