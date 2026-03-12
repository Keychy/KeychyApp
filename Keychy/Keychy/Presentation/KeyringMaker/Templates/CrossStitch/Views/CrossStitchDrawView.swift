//
//  CrossStitchDrawView.swift
//  Keychy
//
//  Created by Jini on 3/10/26.
//

import SwiftUI

struct CrossStitchDrawView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: CrossStitchVM

    @State private var showResetAlert = false
    @State private var isResetting = false
    @State private var swipeDisabled = false

    /// 줌/패닝 상태
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    @Namespace private var unionNamespace

    /// Undo/Redo 연속 실행을 위한 Timer
    @State private var undoTimer: Timer?
    @State private var redoTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white100
                    .ignoresSafeArea()

                // MARK: - 크로스스티치 그리드 (화면 중앙)
                if !isResetting {
                    VStack {
                        Spacer()
                        stitchGrid
                            .padding(.bottom, 50)
                        Spacer()
                    }
                }

                // MARK: - 하단 버튼 + 스레드 팔레트
                VStack(spacing: 15) {
                    Spacer()

                    // Undo/Redo + Draw/Eraser
                    HStack {
                        undoRedoButtons
                        Spacer()
                    }
                    .padding(.horizontal, 26)

                    // 실(Thread) 팔레트
                    threadPalette
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: geometry.size.height * 0.2
                        )
                        .padding(.bottom, 0)
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
        .swipeBackGesture(enabled: !swipeDisabled)
        .onAppear {
            // sheet 닫힘 후 Preview의 swipeBackGesture(enabled: true)가
            // 덮어쓰는 타이밍 이슈 방지를 위해 onAppear에서 state 변경으로 재트리거
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                swipeDisabled = true
            }
        }
        .alert("작업을 취소하시겠습니까?", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) { }
            Button("확인", role: .destructive) {
                isResetting = true
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

// MARK: - Stitch Grid Overlap Constants
private enum StitchOverlap {
    static let horizontal: CGFloat = 0.20
    static let vertical: CGFloat = 0.10
}

// MARK: - Stitch Grid
extension CrossStitchDrawView {

    private var stitchGrid: some View {
        GeometryReader { geometry in
            // 가장자리 셀이 잘리지 않도록 hOverlap만큼 양쪽 여백 확보
            let hOverlapAbs = (geometry.size.width - 52) / CGFloat(max(viewModel.stitchGrid.count, 1)) * StitchOverlap.horizontal
            let availableSize = geometry.size.width - 52 - hOverlapAbs * 2
            let count = viewModel.stitchGrid.count
            let cellSize = count > 0 ? availableSize / CGFloat(count) : availableSize
            let renderW = cellSize * (1 + StitchOverlap.horizontal * 2)
            let renderH = cellSize * (1 + StitchOverlap.vertical * 2)

            ZStack {
                // 그리드 렌더링
                VStack(spacing: -(cellSize * StitchOverlap.vertical * 2)) {
                    ForEach(0..<count, id: \.self) { row in
                        HStack(spacing: -(cellSize * StitchOverlap.horizontal * 2)) {
                            ForEach(0..<count, id: \.self) { col in
                                StitchCell(
                                    stitchColor: viewModel.stitchGrid[row][col],
                                    renderW: renderW,
                                    renderH: renderH,
                                    onTap: { viewModel.paintStitch(row: row, col: col) }
                                )
                            }
                        }
                    }
                }
                // 가장자리 여백(hOverlap)을 포함한 전체 크기로 frame
                .frame(
                    width: availableSize + hOverlapAbs * 2,
                    height: availableSize + hOverlapAbs * 2
                )
                .scaleEffect(scale)
                .offset(offset)
                .allowsHitTesting(false)

                // 그리드와 같은 scaleEffect/offset 적용
                Image(.stitchFrame)
                    .resizable()
                    .scaledToFit()
                    .frame(width: screenWidth - 16)
                    .offset(y: -12)
                    .scaleEffect(scale)
                    .offset(offset)
                    .allowsHitTesting(false)

                // UIKit 제스처 오버레이
                CrossStitchGestureView(
                    onDraw: { point in
                        let totalSize = availableSize + hOverlapAbs * 2
                        let gridOriginX = (geometry.size.width - totalSize) / 2
                        let gridOriginY = (geometry.size.height - totalSize) / 2

                        let adjustedX = (point.x - gridOriginX - offset.width - totalSize / 2) / scale + totalSize / 2
                        let adjustedY = (point.y - gridOriginY - offset.height - totalSize / 2) / scale + totalSize / 2

                        // hOverlapAbs 여백을 빼고 cellSize로 나눔
                        let col = Int((adjustedX - hOverlapAbs) / cellSize)
                        let row = Int((adjustedY - hOverlapAbs) / cellSize)
                        viewModel.paintStitch(row: row, col: col)
                    },
                    onPan: { translation in
                        guard scale > 1.0 else { return }
                        let totalSize = availableSize + hOverlapAbs * 2
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
                        let totalSize = availableSize + hOverlapAbs * 2
                        scale = min(max(scale * delta, 1.0), 4.0)
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

// MARK: - Stitch Cell
struct StitchCell: View {
    let stitchColor: StitchColor
    let renderW: CGFloat
    let renderH: CGFloat
    let onTap: () -> Void

    var body: some View {
        Image(stitchColor.stitchImage)
            .resizable()
            .scaledToFill()
            .frame(width: renderW, height: renderH)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Thread Palette
extension CrossStitchDrawView {
    private var threadPalette: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StitchColor.allCases, id: \.rawValue) { color in
                        Button {
                            viewModel.selectedStitchColor = color
                            viewModel.isDrawMode = true
                            Haptic.impact(style: .light)
                        } label: {
                            threadView(color: color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.vertical, 14)
            }
        }
        .background(Color.gray50)
        .ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder
    private func threadView(color: StitchColor) -> some View {
        let isSelected = viewModel.selectedStitchColor == color && viewModel.isDrawMode

        ZStack(alignment: .top) {
            Image(color.threadImage)
                .resizable()
                .scaledToFit()
                .frame(width: 73, height: 82)
                .offset(y: isSelected ? -20 : 0)
                .animation(
                    .interpolatingSpring(
                        stiffness: 300,
                        damping: 20,
                        initialVelocity: isSelected ? 10 : -5
                    ),
                    value: isSelected
                )
        }
        .frame(width: 73)
    }
}

// MARK: - Undo/Redo Buttons
extension CrossStitchDrawView {
    private var undoRedoButtons: some View {
        GlassEffectContainer {
            HStack(spacing: -15) {
                Button {
                    viewModel.undo()
                    Haptic.impact(style: .light)
                } label: {
                    Image(viewModel.undoStack.isEmpty ? "undoGray" : "undoBlack")
                }
                .disabled(viewModel.undoStack.isEmpty)
                .glassEffectUnion(id: "stitchOptions", namespace: unionNamespace)
                .buttonStyle(.glass)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in startUndoTimer() }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in stopUndoTimer() }
                )

                Button {
                    viewModel.redo()
                    Haptic.impact(style: .light)
                } label: {
                    Image(viewModel.redoStack.isEmpty ? "redoGray" : "redoBlack")
                }
                .disabled(viewModel.redoStack.isEmpty)
                .glassEffectUnion(id: "stitchOptions", namespace: unionNamespace)
                .buttonStyle(.glass)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in startRedoTimer() }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in stopRedoTimer() }
                )
            }
        }
    }

    private func startUndoTimer() {
        guard !viewModel.undoStack.isEmpty else { return }
        Haptic.impact(style: .medium)
        undoTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            viewModel.undo()
            Haptic.impact(style: .light)
        }
    }
    private func stopUndoTimer() { undoTimer?.invalidate(); undoTimer = nil }

    private func startRedoTimer() {
        guard !viewModel.redoStack.isEmpty else { return }
        Haptic.impact(style: .medium)
        redoTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            viewModel.redo()
            Haptic.impact(style: .light)
        }
    }
    private func stopRedoTimer() { redoTimer?.invalidate(); redoTimer = nil }
}

// MARK: - Custom Navigation Bar
extension CrossStitchDrawView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                showResetAlert = true
            }
        } center: {
            Text("자수를 놓아주세요")
        } trailing: {
            NextToolbarButton {
                Task {
                    await viewModel.updateBodyImage()
                    router.push(.crossStitchCustomizing)
                }
            }
            .frame(width: 44, height: 44)
            .offset(x: -4)
        }
    }
}
