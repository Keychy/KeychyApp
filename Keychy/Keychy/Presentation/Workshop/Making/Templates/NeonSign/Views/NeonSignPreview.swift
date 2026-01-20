//
//  NeonSignPreView.swift
//  Keychy
//
//  Created by rundo on 10/29/25.
//

import SwiftUI

struct NeonSignPreView: View {
    @Bindable var router: NavigationRouter<KeyringMakerRoute>
    @State var viewModel: NeonSignVM

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: { await viewModel.fetchTemplate() },
            onMake: {
                router.push(.neonSignCustomizing)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}

#Preview {
    NeonSignPreView(
        router: NavigationRouter<KeyringMakerRoute>(),
        viewModel: NeonSignVM()
    )
    .environment(UserManager.shared)
}
