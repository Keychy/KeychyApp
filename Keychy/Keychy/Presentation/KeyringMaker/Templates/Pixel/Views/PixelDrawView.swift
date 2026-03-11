//
//  PixelDrawView.swift
//  Keychy
//
//  Created by 길지훈 on 11/22/25.
//

import SwiftUI

struct PixelDrawView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: PixelVM
    
    /// 팔레트 표시 여부 (그리기 모드일 때만 표시)
    @State private var showPalette: Bool = true
    @State private var showResetAlert = false
    
    /// 화면 사라지기 전 그리드 렌더링 막기용 파라미터
    @State private var isResetting = false
    
    /// 줌/패닝 상태
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    /// GlassEffect 애니메이션을 위한 네임스페이스
    @Namespace private var unionNamespace

    /// Undo/Redo 연속 실행을 위한 Timer
    @State private var undoTimer: Timer?
    @State private var redoTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white100
                    .ignoresSafeArea()
                
                // MARK: - 픽셀 그리드 (화면 중앙 배치)
                if !isResetting {
                    VStack {
                        Spacer()
                        pixelGrid
                            .padding(.bottom, 50)
                        Spacer()
                    }
                }

                // MARK: - 버튼 + 색상 팔레트 (화면 하단에 고정)
                VStack(spacing: 15) {
                    
                    Spacer()
                    
                    // MARK: - Undo/Redo/그리기/지우기 버튼
                    HStack {
                        undoRedoButtons

                        Spacer()

                        drawEraserButtons
                    }
                    .padding(.horizontal, 26)

                    // MARK: - 색상 팔레트 (애니메이션)
                    colorPalette
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: showPalette ? geometry.size.height * 0.15 : 0
                        )
                        .padding(.bottom, showPalette ? 0 : 30)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .adaptiveTopPaddingAlt()

                
                // MARK: - 커스텀 네비게이션
                customNavigationBar
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .alert("작업을 취소하시겠습니까?", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) { }
            Button("확인", role: .destructive) {
                // 1. 그리드 렌더링 막기
                isResetting = true
                // 2. 초기화 + 화면 이동
                DispatchQueue.main.async {
                    viewModel.resetAll()
                    TabBarManager.show()
                    router.reset()
                }
            }
        } message: {
            Text("지금까지 작업한 내용이 모두 초기화됩니다.")
        }
    }
}

// MARK: - Pixel Grid
extension PixelDrawView {
    private var pixelGrid: some View {
        GeometryReader { geometry in
            let totalSize = geometry.size.width - 36
            let count = viewModel.pixelGrid.count
            let cellSize = count > 0 ? totalSize / CGFloat(count) : totalSize

            ZStack {
                // 그리드 렌더링
                VStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<viewModel.pixelGrid[row].count, id: \.self) { col in
                                PixelCell(
                                    color: viewModel.pixelGrid[row][col],
                                    size: cellSize,
                                    onTap: { viewModel.paintPixel(row: row, col: col) }
                                )
                            }
                        }
                    }
                }
                .frame(width: totalSize, height: totalSize)
                .background(Color.gray50)
                .border(.gray100, width: 1)
                .scaleEffect(scale)
                .offset(offset)
                .allowsHitTesting(false) // 터치는 아래 UIKit 뷰가 처리

                // UIKit 제스처 오버레이
                PixelGestureView(
                    onDraw: { point in
                        // 터치 좌표 → 그리드 셀 좌표 역변환
                        let gridOriginX = (geometry.size.width - totalSize) / 2
                        let gridOriginY = (geometry.size.height - totalSize) / 2

                        let adjustedX = (point.x - gridOriginX - offset.width - totalSize / 2) / scale + totalSize / 2
                        let adjustedY = (point.y - gridOriginY - offset.height - totalSize / 2) / scale + totalSize / 2

                        let col = Int(adjustedX / cellSize)
                        let row = Int(adjustedY / cellSize)
                        viewModel.paintPixel(row: row, col: col)
                    },
                    onPan: { translation in
                        guard scale > 1.0 else { return }
                        let newOffset = CGSize(
                            width: lastOffset.width + translation.width,
                            height: lastOffset.height + translation.height
                        )
                        offset = clampedOffset(newOffset, scale: scale, totalSize: totalSize)
                    },
                    onPanEnd: {
                        lastOffset = offset
                    },
                    onPinch: { delta in
                        let newScale = min(max(scale * delta, 1.0), 4.0)
                        scale = newScale
                        offset = clampedOffset(offset, scale: scale, totalSize: totalSize)
                    },
                    onPinchEnd: {
                        lastScale = scale
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func clampedOffset(
        _ proposedOffset: CGSize,
        scale: CGFloat,
        totalSize: CGFloat
    ) -> CGSize {
        let maxOffset = max(0, (totalSize * scale - totalSize) / 2)
        return CGSize(
            width: min(max(proposedOffset.width, -maxOffset), maxOffset),
            height: min(max(proposedOffset.height, -maxOffset), maxOffset)
        )
    }
}

// MARK: - Pixel Cell
struct PixelCell: View {
    let color: Color
    let size: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .border(.gray100, width: 1)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Undo/Redo Buttons
extension PixelDrawView {
    private var undoRedoButtons: some View {
        GlassEffectContainer {
            HStack(spacing: -15) {
                // Undo 버튼
                Button {
                    viewModel.undo()
                    Haptic.impact(style: .light)
                } label: {
                    Image(viewModel.undoStack.isEmpty ? "undoGray" : "undoBlack")
                }
                .disabled(viewModel.undoStack.isEmpty)
                .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                .buttonStyle(.glass)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            startUndoTimer()
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in
                            stopUndoTimer()
                        }
                )

                // Redo 버튼
                Button {
                    viewModel.redo()
                    Haptic.impact(style: .light)
                } label: {
                    Image(viewModel.redoStack.isEmpty ? "redoGray" : "redoBlack")
                }
                .disabled(viewModel.redoStack.isEmpty)
                .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                .buttonStyle(.glass)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            startRedoTimer()
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in
                            stopRedoTimer()
                        }
                )
            }
        }
    }

    // MARK: - Timer 관련 함수들
    private func startUndoTimer() {
        guard viewModel.undoStack.isEmpty == false else { return }
        Haptic.impact(style: .medium)
        undoTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            viewModel.undo()
            Haptic.impact(style: .light)
        }
    }

    private func stopUndoTimer() {
        undoTimer?.invalidate()
        undoTimer = nil
    }

    private func startRedoTimer() {
        guard viewModel.redoStack.isEmpty == false else { return }
        Haptic.impact(style: .medium)
        redoTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            viewModel.redo()
            Haptic.impact(style: .light)
        }
    }

    private func stopRedoTimer() {
        redoTimer?.invalidate()
        redoTimer = nil
    }
}

// MARK: - Draw/Eraser Buttons
extension PixelDrawView {
    private var drawEraserButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                viewModel.isDrawMode = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showPalette = true
                }
                Haptic.impact(style: .medium)
            }) {
                Image(viewModel.isDrawMode ? "drawWhite" : "drawBlack")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(viewModel.isDrawMode ? .accent : .white100)
            )
            .glassEffect(.regular.interactive(), in: .circle)
            
            
            Button(action: {
                viewModel.isDrawMode = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showPalette = false
                }
                Haptic.impact(style: .medium)
            }) {
                Image(viewModel.isDrawMode ? "eraserBlack" : "eraserWhite")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(viewModel.isDrawMode ? .white100 : .accent)
            )
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }
}

// MARK: - Color Palette
extension PixelDrawView {
    private var colorPalette: some View {
        VStack(spacing: 0) {
            if showPalette {
                ColorPalette(selectedColor: $viewModel.selectedColor)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            showPalette ? Color.gray50 : Color.white100
        )
        .ignoresSafeArea(edges: .bottom)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showPalette)
    }
}

// MARK: - Custom Navigation Bar
extension PixelDrawView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                showResetAlert = true
            }
        } center: {
            Text("그림을 그려주세요")
        } trailing: {
            NextToolbarButton {
                Task {
                    await viewModel.updateBodyImage()
                    router.push(.pixelCustomizing)
                }
            }
            .frame(width: 44, height: 44)
            .offset(x: -4)
        }
    }
}
