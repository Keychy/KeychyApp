//
//  WishHorse26Preview.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI

struct WishHorse26Preview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: WishHorse26VM
    @Environment(UserManager.self) private var userManager

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: {
                await viewModel.fetchTemplate()
                await viewModel.fetchFrames()
                await viewModel.fetchSaddles()
                await viewModel.fetchManes()
            },
            onMake: {
                router.push(.wishHorse26Customizing)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}
