//
//  LenticularPreview.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import SwiftUI

struct LenticularPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: LenticularVM
    @Environment(UserManager.self) private var userManager

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: {
                await viewModel.fetchTemplate()
            },
            onMake: {
                router.push(.lenticularImageSelect)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}
