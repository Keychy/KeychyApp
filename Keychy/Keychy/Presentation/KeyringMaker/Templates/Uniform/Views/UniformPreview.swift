//
//  UniformPreview.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-10.
//

import SwiftUI

struct UniformPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: UniformVM

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: {
                await viewModel.fetchTemplate()
                await viewModel.fetchFrames()
                await viewModel.fetchEffects()
            },
            onMake: {
                router.push(.uniformCustomizing)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}
