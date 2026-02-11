//
//  DuZzonKuFramePreviewView.swift
//  Keychy
//
//  Created by Jini on 2/11/26.
//

import SwiftUI
import PhotosUI
import NukeUI
import Nuke

struct DuZzonKuFramePreviewView: View {
    @Bindable var viewModel: DuZzonKuVM
    let onSceneReady: () -> Void

    @State private var showPhotoSelectSheet = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showEditButton = false
    @State private var isFrameLoaded: Bool = false
    
    // 여러 개의 체커보드 중 어떤 것을 편집 중인지
    @State private var editingRectIndex: Int? = nil
    
    // 시트에서 선택한 액션을 저장
    @State private var pendingAction: PhotoAction? = nil
    
    enum PhotoAction {
        case camera
        case photoLibrary
    }
    
    // 제스처 임시 값
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    @State private var currentOffset: CGSize = .zero
    
    // 크기 설정
    private let targetFrameHeight: CGFloat = 376

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메인 콘텐츠
                VStack {
                    ZStack(alignment: .top) {
                        // 프레임 + 안장 + 갈기 합성 영역
                        VStack {
                            Spacer()
                                .frame(height: 135)

                            compositionView
                        }

                        // frameChain 이미지 (위에 겹침)
                        Image(.frameChain)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                            .offset(y: 4)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 168)
                .opacity(isFrameLoaded ? 1 : 0)

                // 로딩 중일 때
                if !isFrameLoaded {
                    LoadingAlert(type: .short40, message: nil)
                }
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                // 현재 편집 중인 영역에 사진 저장
                if let index = editingRectIndex {
                    viewModel.setPhoto(image, at: index)
                } else {
                    viewModel.selectedPhotoImage = image
                }
                
                // 새 사진 선택 시 변환 초기화
                viewModel.photoScale = 1.0
                viewModel.photoRotation = .zero
                viewModel.photoOffset = .zero
                currentScale = 1.0
                currentRotation = .zero
                currentOffset = .zero
                showEditButton = false
                editingRectIndex = nil
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoSelectSheet, onDismiss: {
            // 시트가 완전히 닫힌 후 액션 실행
            if let action = pendingAction {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    switch action {
                    case .camera:
                        showCamera = true
                    case .photoLibrary:
                        showPhotoPicker = true
                    }
                    pendingAction = nil
                }
            }
        }) {
            PhotoSelectSheet(
                onCameraSelected: {
                    pendingAction = .camera
                },
                onPhotoLibrarySelected: {
                    pendingAction = .photoLibrary
                }
            )
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    // 현재 편집 중인 영역에 사진 저장
                    if let index = editingRectIndex {
                        viewModel.setPhoto(uiImage, at: index)
                    } else {
                        viewModel.selectedPhotoImage = uiImage
                    }
                    
                    // 새 사진 선택 시 변환 초기화
                    viewModel.photoScale = 1.0
                    viewModel.photoRotation = .zero
                    viewModel.photoOffset = .zero
                    currentScale = 1.0
                    currentRotation = .zero
                    currentOffset = .zero
                    showEditButton = false
                    editingRectIndex = nil
                }
            }
        }
        .onAppear {
            // 일반 SwiftUI View는 즉시 준비 완료
            onSceneReady()
        }
    }
    
    private var photoGestures: some Gesture {
        // 확대/축소
        let magnificationGesture = MagnificationGesture(minimumScaleDelta: 0.0)
            .onChanged { value in
                Task { @MainActor in
                    currentScale = value
                }
            }
            .onEnded { value in
                Task { @MainActor in
                    let newScale = viewModel.photoScale * value
                    viewModel.photoScale = min(max(newScale, 0.5), 3.0)
                    currentScale = 1.0
                }
            }
        
        // 회전
        let rotationGesture = RotationGesture(minimumAngleDelta: .zero)
            .onChanged { value in
                Task { @MainActor in
                    currentRotation = value
                }
            }
            .onEnded { value in
                Task { @MainActor in
                    viewModel.photoRotation += value
                    currentRotation = .zero
                }
            }
        
        // 이동
        let dragGesture = DragGesture(minimumDistance: 10)
            .onChanged { value in
                Task { @MainActor in
                    currentOffset = CGSize(
                        width: value.translation.width,
                        height: value.translation.height
                    )
                }
            }
            .onEnded { value in
                Task { @MainActor in
                    viewModel.photoOffset = CGSize(
                        width: viewModel.photoOffset.width + value.translation.width,
                        height: viewModel.photoOffset.height + value.translation.height
                    )
                    currentOffset = .zero
                }
            }
        
        return magnificationGesture
            .simultaneously(with: rotationGesture)
            .simultaneously(with: dragGesture)
    }
    
    private var finalScale: CGFloat {
        let calculatedScale = viewModel.photoScale * currentScale
        return min(max(calculatedScale, 0.5), 3.0)
    }
    
    private var finalRotation: Angle {
        viewModel.photoRotation + currentRotation
    }
    
    private var finalOffset: CGSize {
        CGSize(
            width: viewModel.photoOffset.width + currentOffset.width,
            height: viewModel.photoOffset.height + currentOffset.height
        )
    }
    
    @ViewBuilder
    private var compositionView: some View {
        ZStack(alignment: .center) {
            if let frame = viewModel.selectedFrame {
                LazyImage(url: URL(string: frame.frameURL)) { state in
                    if state.isLoading {
                        LoadingAlert(type: .short40, message: nil)
                            .frame(height: targetFrameHeight)
                    } else if let image = state.image {
                        let frameAspect = (state.imageContainer?.image.size.width ?? 1) / (state.imageContainer?.image.size.height ?? 1)
                        let targetFrameWidth = targetFrameHeight * frameAspect
                        
                        ZStack(alignment: .topLeading) {
                            // 1. 여러 개의 체커보드/사진 영역
                            if let checkerBoardRects = frame.checkerBoardRects {
                                ForEach(Array(checkerBoardRects.enumerated()), id: \.offset) { index, rect in
                                    checkerBoardView(
                                        rect: rect,
                                        index: index,
                                        targetFrameWidth: targetFrameWidth,
                                        targetFrameHeight: targetFrameHeight,
                                        checkerBoardURL: frame.checkerBoardURL
                                    )
                                }
                            }
                            
                            // 2. 프레임 이미지
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: targetFrameHeight)
                                .allowsHitTesting(false)
                        }
                        .frame(width: targetFrameWidth, height: targetFrameHeight)
                        .onAppear {
                            isFrameLoaded = true
                        }
                    }
                }
                .onDisappear {
                    isFrameLoaded = false
                }
                .onAppear {
                    print("checkerBoardRects:", frame.checkerBoardRects ?? [])
                }
            }
        }
    }
    
    @ViewBuilder
    private func checkerBoardView(
        rect: CheckerBoardRect,
        index: Int,
        targetFrameWidth: CGFloat,
        targetFrameHeight: CGFloat,
        checkerBoardURL: String?
    ) -> some View {
        // Firebase에서 정의한 체커보드 실제 영역
        let photoWidth = targetFrameWidth * rect.width
        let photoHeight = targetFrameHeight * rect.height
        let photoX = targetFrameWidth * rect.x
        let photoY = targetFrameHeight * rect.y
        
        let radius = rect.cornerRadius ?? 0
        let clipShape = RoundedRectangle(cornerRadius: radius)
        
        ZStack {
            // 체커보드 이미지 (선택사항, 디버깅용)
            if let checkerBoardURLString = checkerBoardURL,
               let checkerBoardURL = URL(string: checkerBoardURLString) {
                LazyImage(url: checkerBoardURL) { checkerState in
                    if let checkerImage = checkerState.image {
                        checkerImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: photoWidth, height: photoHeight)
                            .clipShape(clipShape)
                    }
                }
            }
            
            // 해당 영역에 저장된 사진
            if let photoImage = viewModel.getPhoto(at: index) {
                ZStack {
                    Image(uiImage: photoImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: photoWidth, height: photoHeight)
                        .scaleEffect(finalScale)
                        .rotationEffect(finalRotation)
                        .offset(finalOffset)
                        .clipShape(clipShape)
                    
                    // 수정 버튼 표시 시 딤 처리
                    if showEditButton && editingRectIndex == index {
                        Color.black20
                    }
                }
                .frame(width: photoWidth, height: photoHeight)
                .clipShape(clipShape)
                .contentShape(clipShape)
                .gesture(photoGestures)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if editingRectIndex == index {
                            showEditButton.toggle()
                        } else {
                            editingRectIndex = index
                            showEditButton = true
                        }
                    }
                }
            } else {
                // 사진이 없을 때 딤 오버레이
                Color.black20
                    .frame(width: photoWidth, height: photoHeight)
                    .clipShape(clipShape)
            }
            
            // 버튼들
            if viewModel.getPhoto(at: index) == nil {
                // 플러스 버튼
                Button {
                    editingRectIndex = index
                    showPhotoSelectSheet = true
                } label: {
                    Image(.plus)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .padding(5)
                }
                .glassEffect(.clear.interactive(), in: .circle)
                .transition(.scale.combined(with: .opacity))
            } else if showEditButton && editingRectIndex == index {
                // 연필 버튼
                Button {
                    showPhotoSelectSheet = true
                    showEditButton = false
                } label: {
                    Image(.editPencil)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .padding(5)
                }
                .glassEffect(.clear.interactive(), in: .circle)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .position(
            x: photoX + photoWidth / 2,
            y: photoY + photoHeight / 2
        )
    }
}
