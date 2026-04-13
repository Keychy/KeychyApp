//
//  LenticularImageSelectView.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-23.
//

import SwiftUI
import PhotosUI

struct LenticularImageSelectView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: LenticularVM

    // MARK: - Card Layout
    private let cardWidthRatio: CGFloat = 0.80
    private let cardAspectRatio: CGFloat = 300.0 / 245.0
    private let backCardOffset: CGFloat = 36
    private let backCardScale: CGFloat = 0.93

    // MARK: - 앞면 카드 (true = A가 앞, false = B가 앞)
    @State private var showingFront = true

    // MARK: - PhotosPicker
    @State private var pickerItemA: PhotosPickerItem?
    @State private var pickerItemB: PhotosPickerItem?

    // MARK: - Gesture 임시 값
    @State private var currentScaleA: CGFloat = 1.0
    @State private var currentOffsetA: CGSize = .zero
    @State private var currentScaleB: CGFloat = 1.0
    @State private var currentOffsetB: CGSize = .zero

    // MARK: - Edit 버튼
    @State private var showEditButtonA = false
    @State private var showEditButtonB = false

    // MARK: - 쉬머 애니메이션
    @State private var shimmerPhase: CGFloat = -0.5

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * cardWidthRatio
            let cardHeight = cardWidth * cardAspectRatio

            ZStack {
                // 카드 밖 탭 → 스왑
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { swapCards() }

                VStack(spacing: 20) {
                    Spacer()

                    cardStack(cardWidth: cardWidth, cardHeight: cardHeight)

                    Spacer()

                    breathingText
                        .padding(.bottom, 40)
                }

                if viewModel.isLoadingImage {
                    LoadingAlert(type: .short40, message: nil)
                }
            }
        }
        .navigationTitle("이미지 선택")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .onChange(of: pickerItemA) {
            Task { await viewModel.loadImage(from: pickerItemA, target: .a) }
        }
        .onChange(of: pickerItemB) {
            Task { await viewModel.loadImage(from: pickerItemB, target: .b) }
        }
    }
}

// MARK: - 카드 스택

extension LenticularImageSelectView {

    /// 두 카드를 ZStack으로 쌓고, showingFront에 따라 scale/offset/opacity/zIndex를 애니메이션
    private func cardStack(cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        ZStack {
            // Card A
            singleCard(
                image: viewModel.imageA,
                pickerItem: $pickerItemA,
                photoScale: viewModel.photoScaleA,
                photoOffset: viewModel.photoOffsetA,
                currentScale: $currentScaleA,
                currentOffset: $currentOffsetA,
                showEditButton: $showEditButtonA,
                target: .a,
                cardWidth: cardWidth,
                cardHeight: cardHeight
            )
            .scaleEffect(showingFront ? 1.0 : backCardScale)
            .offset(
                x: showingFront ? 0 : backCardOffset,
                y: showingFront ? 0 : backCardOffset
            )
            .opacity(showingFront ? 1.0 : 0.5)
            .zIndex(showingFront ? 1 : 0)
            .allowsHitTesting(showingFront)

            // Card B
            singleCard(
                image: viewModel.imageB,
                pickerItem: $pickerItemB,
                photoScale: viewModel.photoScaleB,
                photoOffset: viewModel.photoOffsetB,
                currentScale: $currentScaleB,
                currentOffset: $currentOffsetB,
                showEditButton: $showEditButtonB,
                target: .b,
                cardWidth: cardWidth,
                cardHeight: cardHeight
            )
            .scaleEffect(showingFront ? backCardScale : 1.0)
            .offset(
                x: showingFront ? backCardOffset : 0,
                y: showingFront ? backCardOffset : 0
            )
            .opacity(showingFront ? 0.5 : 1.0)
            .zIndex(showingFront ? 0 : 1)
            .allowsHitTesting(!showingFront)
        }
        .frame(width: cardWidth + backCardOffset * 2,
               height: cardHeight + backCardOffset * 2)
    }
}

// MARK: - 단일 카드

extension LenticularImageSelectView {

    @ViewBuilder
    private func singleCard(
        image: UIImage?,
        pickerItem: Binding<PhotosPickerItem?>,
        photoScale: CGFloat,
        photoOffset: CGSize,
        currentScale: Binding<CGFloat>,
        currentOffset: Binding<CGSize>,
        showEditButton: Binding<Bool>,
        target: LenticularVM.ImageTarget,
        cardWidth: CGFloat,
        cardHeight: CGFloat
    ) -> some View {
        if let image {
            selectedImageCard(
                image: image,
                pickerItem: pickerItem,
                photoScale: photoScale,
                photoOffset: photoOffset,
                currentScale: currentScale,
                currentOffset: currentOffset,
                showEditButton: showEditButton,
                target: target,
                cardWidth: cardWidth,
                cardHeight: cardHeight
            )
        } else {
            placeholderCard(
                pickerItem: pickerItem,
                cardWidth: cardWidth,
                cardHeight: cardHeight
            )
        }
    }

    private func selectedImageCard(
        image: UIImage,
        pickerItem: Binding<PhotosPickerItem?>,
        photoScale: CGFloat,
        photoOffset: CGSize,
        currentScale: Binding<CGFloat>,
        currentOffset: Binding<CGSize>,
        showEditButton: Binding<Bool>,
        target: LenticularVM.ImageTarget,
        cardWidth: CGFloat,
        cardHeight: CGFloat
    ) -> some View {
        // 최소 1.0 → 카드 영역보다 작아지지 않음
        let finalScale = min(max(photoScale * currentScale.wrappedValue, 1.0), 3.0)
        let finalOffset = CGSize(
            width: photoOffset.width + currentOffset.wrappedValue.width,
            height: photoOffset.height + currentOffset.wrappedValue.height
        )

        return ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight)
                .scaleEffect(finalScale)
                .offset(finalOffset)
                .clipped()

            if showEditButton.wrappedValue {
                Color.black.opacity(0.2)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .modifier(CardStyleModifier())
        .contentShape(Rectangle())
        .gesture(photoGesture(
            photoScale: photoScale,
            photoOffset: photoOffset,
            currentScale: currentScale,
            currentOffset: currentOffset,
            target: target,
            cardSize: CGSize(width: cardWidth, height: cardHeight)
        ))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showEditButton.wrappedValue.toggle()
            }
        }
        .overlay {
            if showEditButton.wrappedValue {
                PhotosPicker(selection: pickerItem, matching: .images) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(.black.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func placeholderCard(
        pickerItem: Binding<PhotosPickerItem?>,
        cardWidth: CGFloat,
        cardHeight: CGFloat
    ) -> some View {
        ZStack {
            Image(.polaroidPH)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

            Color.black.opacity(0.2)

            PhotosPicker(selection: pickerItem, matching: .images) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .buttonStyle(.plain)
        }
        .frame(width: cardWidth, height: cardHeight)
        .modifier(CardStyleModifier())
    }
}

// MARK: - 카드 스타일 (테두리 + 그림자)

extension LenticularImageSelectView {

    private struct CardStyleModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - 카드 스왑 애니메이션

extension LenticularImageSelectView {

    /// 앞 카드가 뒤로, 뒤 카드가 앞으로 — spring 애니메이션
    private func swapCards() {
        showEditButtonA = false
        showEditButtonB = false

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingFront.toggle()
        }
    }
}

// MARK: - Tap to Switch! 숨쉬는 텍스트

extension LenticularImageSelectView {

    private var breathingText: some View {
        Text("탭해서 전환")
            .font(.subheadline)
            .fontWeight(.medium)
            .tracking(3)
            .foregroundStyle(.gray)
            .mask {
                GeometryReader { geo in
                    ZStack {
                        // 베이스 (항상 은은하게 보임)
                        Color.white.opacity(0.3)

                        // 쉬머 하이라이트 (빛줄기가 흘러감)
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: geo.size.width * shimmerPhase)
                    }
                }
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerPhase = 1.5
                }
            }
    }
}

// MARK: - 제스처

extension LenticularImageSelectView {

    private func photoGesture(
        photoScale: CGFloat,
        photoOffset: CGSize,
        currentScale: Binding<CGFloat>,
        currentOffset: Binding<CGSize>,
        target: LenticularVM.ImageTarget,
        cardSize: CGSize
    ) -> some Gesture {
        let magnification = MagnificationGesture(minimumScaleDelta: 0.0)
            .onChanged { value in
                currentScale.wrappedValue = value
            }
            .onEnded { value in
                viewModel.applyScale(value, target: target, cardSize: cardSize)
                currentScale.wrappedValue = 1.0
            }

        let drag = DragGesture(minimumDistance: 10)
            .onChanged { value in
                // 드래그 중에도 실시간 클램핑 → 빈 영역 노출 방지
                let totalScale = min(max(photoScale * currentScale.wrappedValue, 1.0), 3.0)
                let maxOff = viewModel.maxOffset(for: target, scale: totalScale, cardSize: cardSize)
                let proposedX = photoOffset.width + value.translation.width
                let proposedY = photoOffset.height + value.translation.height
                currentOffset.wrappedValue = CGSize(
                    width: min(max(proposedX, -maxOff.width), maxOff.width) - photoOffset.width,
                    height: min(max(proposedY, -maxOff.height), maxOff.height) - photoOffset.height
                )
            }
            .onEnded { value in
                viewModel.applyOffset(value.translation, target: target, cardSize: cardSize)
                currentOffset.wrappedValue = .zero
            }

        return magnification.simultaneously(with: drag)
    }
}

// MARK: - 툴바

extension LenticularImageSelectView {

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                viewModel.imageA = nil
                viewModel.imageB = nil
                router.pop()
            } label: {
                Image(.backIcon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("다음") {
                viewModel.composeAtlas()
                router.push(.lenticularFusion)
            }
            .disabled(!viewModel.canProceed)
            .typography(.suit17B)
            .foregroundStyle(viewModel.canProceed ? .main500 : .gray300)
        }
    }
}
