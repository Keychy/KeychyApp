//
//  BundleCreateView+SelectSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI

// MARK: - 키링 버튼
extension BundleCreateView {
    func keyringButtons(carabiner: Carabiner) -> some View {
        GeometryReader { geometry in
            let sceneWidth: CGFloat = 402
            let sceneHeight: CGFloat = 874
            let scale = max(geometry.size.width / sceneWidth, geometry.size.height / sceneHeight)

            let contentW = sceneWidth * scale
            let contentH = sceneHeight * scale

            let dx = (geometry.size.width - contentW) / 2
            let dy = (geometry.size.height - contentH) / 2

            ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
                let viewX = dx + carabiner.keyringXPosition[index] * scale
                let viewY = dy + carabiner.keyringYPosition[index] * scale

                AddKeyringButton(
                    isSelected: selectedPosition == index,
                    action: {
                        selectedPosition = index
                        showKeyringSheet = true
                    }
                )
                .position(x: viewX, y: viewY)
                .opacity(isSceneReady ? 1.0 : 0.0)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 하단 시트
extension BundleCreateView {
    var sheetContent: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            if showItemSheet {
                // 시트가 있을 때: 셀렉터 + 시트가 함께 움직임
                VStack(spacing: 0) {
                    BundleSheetToggleButtons(
                        showItemSheet: $showItemSheet,
                        isBackgroundMode: $isBackgroundMode
                    )
                    .padding(.bottom, 10)

                    DraggableSheet(
                        sheetHeight: $sheetHeight,
                        header: BundleSheetFilterBar(viewModel: bundleVM),
                        content: itemSheetContent,
                        onDismiss: {
                            showItemSheet = false
                        }
                    )
                }
                .transition(.move(edge: .bottom))
            } else {
                // 시트가 없을 때: 셀렉터만 하단에 고정
                BundleSheetToggleButtons(
                    showItemSheet: $showItemSheet,
                    isBackgroundMode: $isBackgroundMode
                )
                .padding(.bottom, 50)
                .transition(.identity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showItemSheet)
    }

    @ViewBuilder
    var itemSheetContent: some View {
        if isBackgroundMode {
            SelectBackgroundSheet(
                viewModel: bundleVM,
                selectedBG: bundleVM.newSelectedBackground,
                onBackgroundTap: { bg in
                    bundleVM.newSelectedBackground = bg
                }
            )
        } else {
            SelectCarabinerSheet(
                viewModel: bundleVM,
                selectedCarabiner: bundleVM.newSelectedCarabiner,
                onCarabinerTap: { carabiner in
                    bundleVM.newSelectedCarabiner = carabiner
                }
            )
        }
    }

    var keyringSheetContent: some View {
        VStack(spacing: 18) {
            Text("키링 선택")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.top, 20)

            if bundleVM.keyring.isEmpty {
                VStack(spacing: 16) {
                    Image(.surprisedAlert)

                    Text("공방에서 키링을 만들어보세요.\n아직 만들어진 키링이 없어요.")
                        .typography(.suit15R)
                        .foregroundStyle(.black100)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(bundleVM.sortedKeyringsForSelection(selectedKeyrings: selectedKeyrings, selectedPosition: selectedPosition), id: \.self) { keyring in
                            keyringCell(keyring: keyring)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .presentationDetents([.fraction(0.45), .fraction(0.85)])
        .presentationDragIndicator(.visible)
    }

    func keyringCell(keyring: Keyring) -> some View {
        let isSelectedHere = selectedKeyrings[selectedPosition]?.id == keyring.id
        let isSelectedElsewhere = selectedKeyrings.values.contains { $0.id == keyring.id } && !isSelectedHere

        return Button {
            if isSelectedHere {
                selectedKeyrings[selectedPosition] = nil
                keyringOrder.removeAll { $0 == selectedPosition }
            } else if !isSelectedElsewhere {
                if selectedKeyrings[selectedPosition] != nil {
                    keyringOrder.removeAll { $0 == selectedPosition }
                }
                selectedKeyrings[selectedPosition] = keyring
                keyringOrder.append(selectedPosition)
                showKeyringSheet = false
            }
            sceneRefreshId = UUID()
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    ZStack {
                        CollectionCellView(keyring: keyring)
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                            .cornerRadius(10)

                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelectedHere ? .mainOpacity80 : .clear, lineWidth: 1.8)
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)

                        if isSelectedElsewhere {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.black50)
                                .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                        }
                    }

                    Text(keyring.name)
                        .typography(isSelectedHere ? .notosans14SB : .notosans14M)
                        .foregroundStyle(isSelectedHere ? .main500 : .black100)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if isSelectedElsewhere || isSelectedHere {
                    Text("장착 중")
                        .foregroundStyle(.white100)
                        .typography(.suit13M)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 20).fill(.mainOpacity80))
                        .padding(.top, 5)
                        .padding(.trailing, 5)
                }
            }
        }
        .disabled(keyring.status == .packaged || keyring.status == .published || isSelectedElsewhere)
    }
}
