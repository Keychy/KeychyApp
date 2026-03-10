//
//  PixelPreviewView.swift
//  Keychy
//
//  Created by 길지훈 on 11/22/25.
//

import SwiftUI

struct PixelPreviewView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: PixelVM
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
            PixelSizeSelection { selectedSize in
                viewModel.setGridSize(selectedSize)
                router.push(.pixelDraw)
            }
        }
    }
}
