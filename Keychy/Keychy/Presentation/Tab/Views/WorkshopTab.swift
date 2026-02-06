//
//  WorkshopTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct WorkshopTab: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var bundleViewModel: BundleViewModel
    @Bindable var collectionViewModel: CollectionViewModel

    @State private var acrylicPhotoVM: AcrylicPhotoVM?
    @State private var neonSignVM: NeonSignVM?
    @State private var polaroidVM: PolaroidVM?
    @State private var clearSketchVM: ClearSketchVM?
    @State private var pixelKeyringVM: PixelVM?
    @State private var speechBubbleVM: SpeechBubbleVM?
    @State private var workshopViewModel = WorkshopViewModel(userManager: UserManager.shared)

    var body: some View {
        NavigationStack(path: $router.path) {
            WorkshopView(
                router: router,
                viewModel: workshopViewModel
            )
            .navigationDestination(for: WorkshopRoute.self) { route in
                destination(for: route)
            }
        }
        .tint(.black)
    }

    // MARK: - Destinations
    @ViewBuilder
    private func destination(for route: WorkshopRoute) -> some View {
        switch route {
        // MARK: - 공통 프리뷰
        case .workshopPreview(let item):
            if let template = item.base as? KeyringTemplate {
                WorkshopItemDetailView(router: router, viewModel: workshopViewModel, item: template)
            } else if let background = item.base as? Background {
                WorkshopItemDetailView(router: router, viewModel: workshopViewModel, item: background, bundleViewModel: bundleViewModel)
            } else if let carabiner = item.base as? Carabiner {
                WorkshopItemDetailView(router: router, viewModel: workshopViewModel, item: carabiner, bundleViewModel: bundleViewModel)
            } else if let particle = item.base as? Particle {
                WorkshopItemDetailView(router: router, viewModel: workshopViewModel, item: particle)
            } else if let sound = item.base as? Sound {
                WorkshopItemDetailView(router: router, viewModel: workshopViewModel, item: sound)
            }

        // MARK: - 내 창고뷰
        case .myItems:
            WorkshopMyItemsView(router: router)

        // MARK: - 템플릿 목록뷰
        case .workshopTemplates:
            WorkshopTemplatesView(router: router)

        // MARK: - 재화 구매뷰
        case .coinCharge:
            CoinChargeView(router: router)
            
        // MARK: - 위젯 설정용
        case .widgetSettingView:
            WidgetSettingView(router: router)

        // MARK: - AcrylicPhoto
        case .acrylicPhotoPreview:
            AcrylicPhotoPreView(router: router, viewModel: getAcrylicPhotoVM())
        case .acrylicPhotoCrop:
            AcrylicPhotoCropView(router: router, viewModel: getAcrylicPhotoVM())
        case .acrylicPhotoEdited:
            AcrylicPhotoEditedView(router: router, viewModel: getAcrylicPhotoVM())
        case .acrylicPhotoCustomizing:
            KeyringCustomizingView(
                router: router,
                viewModel: getAcrylicPhotoVM(),
                nextRoute: .acrylicPhotoInfoInput
            )
        case .acrylicPhotoInfoInput:
            KeyringInfoInputView(
                router: router,
                viewModel: getAcrylicPhotoVM(),
                nextRoute: .acrylicPhotoComplete
            )
        case .acrylicPhotoComplete:
            KeyringCompleteView(
                router: router,
                viewModel: getAcrylicPhotoVM(),
                navigationTitle: "키링이 완성되었어요!"
            )

        // MARK: - NeonSign
        case .neonSignPreview:
            NeonSignPreView(router: router, viewModel: getNeonSignVM())
        case .neonSignCustomizing:
            KeyringCustomizingView(
                router: router,
                viewModel: getNeonSignVM(),
                nextRoute: .neonSignInfoInput
            )
        case .neonSignInfoInput:
            KeyringInfoInputView(
                router: router,
                viewModel: getNeonSignVM(),
                nextRoute: .neonSignComplete
            )
        case .neonSignComplete:
            KeyringCompleteView(
                router: router,
                viewModel: getNeonSignVM(),
                navigationTitle: "키링이 완성되었어요!"
            )

        // MARK: - Polaroid
        case .polaroidPreview:
            PolaroidPreview(router: router, viewModel: getPolaroidVM())
        case .polaroidCustomizing:
            KeyringCustomizingView(
                router: router,
                viewModel: getPolaroidVM(),
                nextRoute: .polaroidInfoInput
            )
        case .polaroidInfoInput:
            KeyringInfoInputView(
                router: router,
                viewModel: getPolaroidVM(),
                nextRoute: .polaroidComplete
            )
        case .polaroidComplete:
            KeyringCompleteView(
                router: router,
                viewModel: getPolaroidVM(),
                navigationTitle: "키링이 완성되었어요!"
            )

        // MARK: - ClearSketch
        case .clearSketchPreview:
            ClearSketchPreview(router: router, viewModel: getClearSketchVM())
        case .clearSketchDrawing:
            ClearSketchDrawingView(router: router, viewModel: getClearSketchVM())
        case .clearSketchCrop:
            ClearSketchCropView(router: router, viewModel: getClearSketchVM())
        case .clearSketchCustomizing:
            KeyringCustomizingView(
                router: router,
                viewModel: getClearSketchVM(),
                nextRoute: .clearSketchInfoInput
            )
        case .clearSketchInfoInput:
            KeyringInfoInputView(
                router: router,
                viewModel: getClearSketchVM(),
                nextRoute: .clearSketchComplete
            )
        case .clearSketchComplete:
            KeyringCompleteView(
                router: router,
                viewModel: getClearSketchVM(),
                navigationTitle: "키링이 완성되었어요!"
            )

        // MARK: - Pixel
        case .pixelPreview:
            PixelPreviewView(router: router, viewModel: getPixelKeyringVM())
        case .pixelDraw:
            PixelDrawView(router: router, viewModel: getPixelKeyringVM())
        case .pixelCustomizing:
            KeyringCustomizingView(
                router: router,
                viewModel: getPixelKeyringVM(),
                nextRoute: .pixelInfoInput
            )
        case .pixelInfoInput:
            KeyringInfoInputView(
                router: router,
                viewModel: getPixelKeyringVM(),
                nextRoute: .pixelComplete
            )
        case .pixelComplete:
            KeyringCompleteView(
                router: router,
                viewModel: getPixelKeyringVM(),
                navigationTitle: "키링이 완성되었어요!"
            )

        // MARK: - SpeechBubble
        case .speechBubblePreview:
            SpeechBubblePreview(router: router, viewModel: getSpeechBubbleVM())
        case .speechBubbleCustomizing:
            KeyringCustomizingView(
                router: router,
                viewModel: getSpeechBubbleVM(),
                nextRoute: .speechBubbleInfoInput
            )
        case .speechBubbleInfoInput:
            KeyringInfoInputView(
                router: router,
                viewModel: getSpeechBubbleVM(),
                nextRoute: .speechBubbleComplete
            )
        case .speechBubbleComplete:
            KeyringCompleteView(
                router: router,
                viewModel: getSpeechBubbleVM(),
                navigationTitle: "키링이 완성되었어요!"
            )

        // MARK: - 선물 포장 완료
        case .packageComplete(let keyringDocumentId, let postOfficeId, let templateId, let shareLink):
            KeyringPackageCompleteView(
                router: router,
                viewModel: getViewModelForTemplate(templateId),
                keyringDocumentId: keyringDocumentId,
                postOfficeId: postOfficeId,
                shareLink: shareLink
            )

        // MARK: - Bundle
        case .bundleInventoryView:
            BundleInventoryView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
        case .bundleDetailView:
            BundleDetailView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
        case .bundleCreateView:
            BundleCreateView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
        case .bundleNameInputView:
            BundleNameInputView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
        case .bundleNameEditView:
            BundleNameEditView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
        case .bundleEditView:
            BundleEditView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
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

    // MARK: - ViewModel by TemplateId
    private func getViewModelForTemplate(_ templateId: String) -> any KeyringViewModelProtocol {
        switch templateId {
        case "AcrylicPhoto":
            return getAcrylicPhotoVM()
        case "NeonSign":
            return getNeonSignVM()
        case "Polaroid":
            return getPolaroidVM()
        case "ClearSketch":
            return getClearSketchVM()
        case "PixelKeyring":
            return getPixelKeyringVM()
        case "SpeechBubble":
            return getSpeechBubbleVM()
        default:
            return getPolaroidVM()
        }
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
