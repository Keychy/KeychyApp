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
        KeyringSelectionContent(
            searchText: $keyringSearchText,
            keyrings: sortedKeyringsForSelection,
            isLoading: false,
            gridColumns: gridColumns,
            cellWidth: threeGridCellWidth,
            cellHeight: threeGridCellHeight,
            isSelectedHere: { keyring in
                selectedKeyrings[selectedPosition]?.id == keyring.id
            },
            isSelectedElsewhere: { keyring in
                selectedKeyrings.values.contains { $0.id == keyring.id } &&
                !(selectedKeyrings[selectedPosition]?.id == keyring.id)
            },
            onTapSelect: { keyring in
                if selectedKeyrings[selectedPosition] != nil {
                    keyringOrder.removeAll { $0 == selectedPosition }
                }
                selectedKeyrings[selectedPosition] = keyring
                keyringOrder.append(selectedPosition)
                showKeyringSheet = false
                sceneRefreshId = UUID()
            },
            onTapDeselect: { keyring in
                selectedKeyrings[selectedPosition] = nil
                keyringOrder.removeAll { $0 == selectedPosition }
                sceneRefreshId = UUID()
            }
        )
        .padding(.horizontal, 20)
        .presentationDetents([.fraction(0.45), .fraction(0.95)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 정렬된 키링 목록 (필터링은 KeyringSelectionContent에서 처리)
    var sortedKeyringsForSelection: [Keyring] {
        bundleVM.sortedKeyringsForSelection(
            selectedKeyrings: selectedKeyrings,
            selectedPosition: selectedPosition
        )
    }
}
