//
//  PolaroidPreview.swift
//  Keychy
//
//  폴라로이드 템플릿 프리뷰
//

import SwiftUI

struct PolaroidPreview: View {
    @Bindable var router: NavigationRouter<KeyringMakerRoute>
    @State var viewModel: PolaroidVM

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: {
                await viewModel.fetchTemplate()
                await viewModel.fetchFrames()
            },
            onMake: {
                router.push(.polaroidCustomizing)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}

#Preview {
    PolaroidPreview(
        router: NavigationRouter<KeyringMakerRoute>(),
        viewModel: PolaroidVM()
    )
    .environment(UserManager.shared)
}
