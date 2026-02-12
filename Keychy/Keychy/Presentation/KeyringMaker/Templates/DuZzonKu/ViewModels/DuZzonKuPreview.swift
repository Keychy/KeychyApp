//
//  DuZzonKuPreview.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI

struct DuZzonKuPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: DuZzonKuVM
    @Environment(UserManager.self) private var userManager

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: {
                await viewModel.fetchTemplate()
                await viewModel.fetchFrames()
            },
            onMake: {
                router.push(.duZzonKuCustomizing)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}
