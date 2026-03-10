//
//  CrossStitchPreview.swift
//  Keychy
//
//  Created by Jini on 3/10/26.
//

import SwiftUI

struct CrossStitchPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: CrossStitchVM
    @Environment(UserManager.self) private var userManager
    @State private var showSizeSelector = false

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: { await viewModel.fetchTemplate() },
            onMake: {
                showSizeSelector = true
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
        .sheet(isPresented: $showSizeSelector) {
            CrossStitchSizeSelection { selectedSize in
                viewModel.setGridSize(selectedSize)
                router.push(.crossStitchDraw)
            }
        }
    }
}
