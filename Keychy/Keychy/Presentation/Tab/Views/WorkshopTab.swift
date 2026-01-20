//
//  WorkshopTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct WorkshopTab: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var keyringMakerRouter: NavigationRouter<KeyringMakerRoute>
    @Bindable var festivalRouter: NavigationRouter<FestivalRoute>
    @Bindable var festivalVM: Showcase25BoardViewModel

    @State private var acrylicPhotoVM: AcrylicPhotoVM?
    @State private var neonSignVM: NeonSignVM?
    @State private var polaroidVM: PolaroidVM?
    @State private var clearSketchVM: ClearSketchVM?
    @State private var pixelKeyringVM: PixelVM?
    @State private var speechBubbleVM: SpeechBubbleVM?
    @State private var workshopViewModel = WorkshopViewModel(userManager: UserManager.shared)

    var body: some View {
        ZStack {
            // MARK: - Workshop (마켓플레이스) NavigationStack
            NavigationStack(path: $router.path) {
                WorkshopView(
                    router: router,
                    keyringMakerRouter: keyringMakerRouter,
                    viewModel: workshopViewModel
                )
                .navigationDestination(for: WorkshopRoute.self) { route in
                    workshopDestination(for: route)
                }
            }
            .tint(.black)

            // MARK: - KeyringMaker (제작 플로우) NavigationStack
            if !keyringMakerRouter.path.isEmpty {
                NavigationStack(path: $keyringMakerRouter.path) {
                    EmptyView()
                        .navigationDestination(for: KeyringMakerRoute.self) { route in
                            keyringMakerDestination(for: route)
                        }
                }
                .tint(.black)
            }
        }
    }

    // MARK: - Workshop Destinations
    @ViewBuilder
    private func workshopDestination(for route: WorkshopRoute) -> some View {
        switch route {
        // MARK: - 공통 프리뷰
        case .workshopPreview(let item):
            if let template = item.base as? KeyringTemplate {
                WorkshopPreview(router: router, viewModel: workshopViewModel, item: template)
            } else if let background = item.base as? Background {
                WorkshopPreview(router: router, viewModel: workshopViewModel, item: background)
            } else if let carabiner = item.base as? Carabiner {
                WorkshopPreview(router: router, viewModel: workshopViewModel, item: carabiner)
            } else if let particle = item.base as? Particle {
                WorkshopPreview(router: router, viewModel: workshopViewModel, item: particle)
            } else if let sound = item.base as? Sound {
                WorkshopPreview(router: router, viewModel: workshopViewModel, item: sound)
            }

        // MARK: - 내 창고뷰
        case .myItems:
            MyItemsView(router: router)

        // MARK: - 템플릿 목록뷰
        case .workshopTemplates:
            WorkshopTemplatesView(router: router, keyringMakerRouter: keyringMakerRouter)

        // MARK: - 재화 구매뷰
        case .coinCharge:
            CoinChargeView(router: router)

        // MARK: - 쇼케이스용 페스티벌 임시 라우트
        case .showcase25BoardView:
            Showcase25BoardView(festivalRouter: festivalRouter, keyringMakerRouter: keyringMakerRouter, viewModel: festivalVM)

        case .festivalKeyringDetailView(let keyring):
            FestivalKeyringDetailView(
                festivalRouter: festivalRouter,
                keyringMakerRouter: keyringMakerRouter,
                viewModel: festivalVM,
                keyring: keyring
            )
        }
    }

    // MARK: - KeyringMaker Destinations
    @ViewBuilder
    private func keyringMakerDestination(for route: KeyringMakerRoute) -> some View {
        switch route {
        // MARK: - 재화 구매 (공통)
        case .coinCharge:
            CoinChargeView(keyringMakerRouter: keyringMakerRouter)

        // MARK: - AcrylicPhoto
        case .acrylicPhotoPreview:
            AcrylicPhotoPreView(router: keyringMakerRouter, viewModel: getAcrylicPhotoVM())
        case .acrylicPhotoCrop:
            AcrylicPhotoCropView(router: keyringMakerRouter, viewModel: getAcrylicPhotoVM())
        case .acrylicPhotoEdited:
            AcrylicPhotoEditedView(router: keyringMakerRouter, viewModel: getAcrylicPhotoVM())
        case .acrylicPhotoCustomizing:
            KeyringCustomizingView(
                router: keyringMakerRouter,
                viewModel: getAcrylicPhotoVM(),
                nextRoute: .acrylicPhotoInfoInput
            )
        case .acrylicPhotoInfoInput:
            KeyringInfoInputView(
                router: keyringMakerRouter,
                viewModel: getAcrylicPhotoVM(),
                nextRoute: .acrylicPhotoComplete
            )
        case .acrylicPhotoComplete:
            KeyringCompleteView(
                router: keyringMakerRouter,
                viewModel: getAcrylicPhotoVM(),
                navigationTitle: "키링이 완성되었어요!",
                onCloseFromFestival: festivalVM.isFromFestivalTab ? { router in
                    festivalVM.onKeyringCompleteFromFestivalKeyringMaker?(router)
                } : nil
            )

        // MARK: - NeonSign
        case .neonSignPreview:
            NeonSignPreView(router: keyringMakerRouter, viewModel: getNeonSignVM())
        case .neonSignCustomizing:
            KeyringCustomizingView(
                router: keyringMakerRouter,
                viewModel: getNeonSignVM(),
                nextRoute: .neonSignInfoInput
            )
        case .neonSignInfoInput:
            KeyringInfoInputView(
                router: keyringMakerRouter,
                viewModel: getNeonSignVM(),
                nextRoute: .neonSignComplete
            )
        case .neonSignComplete:
            KeyringCompleteView(
                router: keyringMakerRouter,
                viewModel: getNeonSignVM(),
                navigationTitle: "키링이 완성되었어요!",
                onCloseFromFestival: festivalVM.isFromFestivalTab ? { router in
                    festivalVM.onKeyringCompleteFromFestivalKeyringMaker?(router)
                } : nil
            )

        // MARK: - Polaroid
        case .polaroidPreview:
            PolaroidPreview(router: keyringMakerRouter, viewModel: getPolaroidVM())
        case .polaroidCustomizing:
            KeyringCustomizingView(
                router: keyringMakerRouter,
                viewModel: getPolaroidVM(),
                nextRoute: .polaroidInfoInput
            )
        case .polaroidInfoInput:
            KeyringInfoInputView(
                router: keyringMakerRouter,
                viewModel: getPolaroidVM(),
                nextRoute: .polaroidComplete
            )
        case .polaroidComplete:
            KeyringCompleteView(
                router: keyringMakerRouter,
                viewModel: getPolaroidVM(),
                navigationTitle: "키링이 완성되었어요!",
                onCloseFromFestival: festivalVM.isFromFestivalTab ? { router in
                    festivalVM.onKeyringCompleteFromFestivalKeyringMaker?(router)
                } : nil
            )

        // MARK: - ClearSketch
        case .clearSketchPreview:
            ClearSketchPreview(router: keyringMakerRouter, viewModel: getClearSketchVM())
        case .clearSketchDrawing:
            ClearSketchDrawingView(router: keyringMakerRouter, viewModel: getClearSketchVM())
        case .clearSketchCrop:
            ClearSketchCropView(router: keyringMakerRouter, viewModel: getClearSketchVM())
        case .clearSketchCustomizing:
            KeyringCustomizingView(
                router: keyringMakerRouter,
                viewModel: getClearSketchVM(),
                nextRoute: .clearSketchInfoInput
            )
        case .clearSketchInfoInput:
            KeyringInfoInputView(
                router: keyringMakerRouter,
                viewModel: getClearSketchVM(),
                nextRoute: .clearSketchComplete
            )
        case .clearSketchComplete:
            KeyringCompleteView(
                router: keyringMakerRouter,
                viewModel: getClearSketchVM(),
                navigationTitle: "키링이 완성되었어요!",
                onCloseFromFestival: festivalVM.isFromFestivalTab ? { router in
                    festivalVM.onKeyringCompleteFromFestivalKeyringMaker?(router)
                } : nil
            )

        // MARK: - Pixel
        case .pixelPreview:
            PixelPreviewView(router: keyringMakerRouter, viewModel: getPixelKeyringVM())
        case .pixelDraw:
            PixelDrawView(router: keyringMakerRouter, viewModel: getPixelKeyringVM())
        case .pixelCustomizing:
            KeyringCustomizingView(
                router: keyringMakerRouter,
                viewModel: getPixelKeyringVM(),
                nextRoute: .pixelInfoInput
            )
        case .pixelInfoInput:
            KeyringInfoInputView(
                router: keyringMakerRouter,
                viewModel: getPixelKeyringVM(),
                nextRoute: .pixelComplete
            )
        case .pixelComplete:
            KeyringCompleteView(
                router: keyringMakerRouter,
                viewModel: getPixelKeyringVM(),
                navigationTitle: "키링이 완성되었어요!",
                onCloseFromFestival: festivalVM.isFromFestivalTab ? { router in
                    festivalVM.onKeyringCompleteFromFestivalKeyringMaker?(router)
                } : nil
            )

        // MARK: - SpeechBubble
        case .speechBubblePreview:
            SpeechBubblePreview(router: keyringMakerRouter, viewModel: getSpeechBubbleVM())
        case .speechBubbleCustomizing:
            KeyringCustomizingView(
                router: keyringMakerRouter,
                viewModel: getSpeechBubbleVM(),
                nextRoute: .speechBubbleInfoInput
            )
        case .speechBubbleInfoInput:
            KeyringInfoInputView(
                router: keyringMakerRouter,
                viewModel: getSpeechBubbleVM(),
                nextRoute: .speechBubbleComplete
            )
        case .speechBubbleComplete:
            KeyringCompleteView(
                router: keyringMakerRouter,
                viewModel: getSpeechBubbleVM(),
                navigationTitle: "키링이 완성되었어요!",
                onCloseFromFestival: festivalVM.isFromFestivalTab ? { router in
                    festivalVM.onKeyringCompleteFromFestivalKeyringMaker?(router)
                } : nil
            )
        }
    }

    // MARK: - ViewModel Lazy Getters
    private func getAcrylicPhotoVM() -> AcrylicPhotoVM {
        guard let viewModel = acrylicPhotoVM else {
            let newViewModel = AcrylicPhotoVM()
            acrylicPhotoVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    private func getNeonSignVM() -> NeonSignVM {
        guard let viewModel = neonSignVM else {
            let newViewModel = NeonSignVM()
            neonSignVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    private func getPolaroidVM() -> PolaroidVM {
        guard let viewModel = polaroidVM else {
            let newViewModel = PolaroidVM()
            polaroidVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    private func getClearSketchVM() -> ClearSketchVM {
        guard let viewModel = clearSketchVM else {
            let newViewModel = ClearSketchVM()
            clearSketchVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    private func getPixelKeyringVM() -> PixelVM {
        guard let viewModel = pixelKeyringVM else {
            let newViewModel = PixelVM()
            pixelKeyringVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    private func getSpeechBubbleVM() -> SpeechBubbleVM {
        guard let viewModel = speechBubbleVM else {
            let newViewModel = SpeechBubbleVM()
            speechBubbleVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    // MARK: - ViewModel Reset
    func resetAcrylicPhotoVM() {
        acrylicPhotoVM = nil
    }

    func resetNeonSignVM() {
        neonSignVM = nil
    }

    func resetPolaroidVM() {
        polaroidVM = nil
    }

    func resetClearSketchVM() {
        clearSketchVM = nil
    }

    func resetPixelKeyringVM() {
        pixelKeyringVM = nil
    }

    func resetSpeechBubbleVM() {
        speechBubbleVM = nil
    }
}
