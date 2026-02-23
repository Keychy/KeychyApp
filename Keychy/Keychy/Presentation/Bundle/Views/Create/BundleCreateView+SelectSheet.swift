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
                        if showItemSheet {
                            // 배경/카라비너 시트 닫기 → 닫힌 후 키링 시트 표시
                            showItemSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showKeyringSheet = true
                            }
                        } else {
                            showKeyringSheet = true
                        }
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

            // 시트 레이어 (항상 존재, 오프셋으로 숨김 → 즉시 반응)
            DraggableSheet(
                sheetHeight: $sheetHeight,
                header: BundleSheetFilterBar(viewModel: bundleVM),
                content: itemSheetContent,
                onDismiss: {
                    showItemSheet = false
                }
            )
            .offset(y: showItemSheet ? 0 : sheetHeight)
            .allowsHitTesting(showItemSheet)

            // 버튼 레이어 (matchedGeometryEffect로 위치만 보간)
            if showItemSheet {
                BundleSheetToggleButtons(
                    showItemSheet: $showItemSheet,
                    isBackgroundMode: $isBackgroundMode
                )
                .matchedGeometryEffect(id: "toggleButtons", in: sheetButtonNamespace)
                .padding(.bottom, sheetHeight + 10)
            } else {
                BundleSheetToggleButtons(
                    showItemSheet: $showItemSheet,
                    isBackgroundMode: $isBackgroundMode
                )
                .matchedGeometryEffect(id: "toggleButtons", in: sheetButtonNamespace)
                .padding(.bottom, 50)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showItemSheet)
        .onChange(of: showItemSheet) { _, isShowing in
            if isShowing {
                sheetHeight = UIScreen.main.bounds.height * 0.4
            }
        }
    }
    
    var itemSheetContent: some View {
        ZStack(alignment: .top) {
            SelectBackgroundSheet(
                viewModel: bundleVM,
                selectedBG: bundleVM.newSelectedBackground,
                onBackgroundTap: { bg in
                    bundleVM.newSelectedBackground = bg
                }
            )
            .opacity(isBackgroundMode ? 1 : 0)
            .allowsHitTesting(isBackgroundMode)

            SelectCarabinerSheet(
                viewModel: bundleVM,
                selectedCarabiner: bundleVM.newSelectedCarabiner,
                onCarabinerTap: { carabiner in
                    if carabiner.carabiner.isLottie { isSceneReady = false }
                    bundleVM.newSelectedCarabiner = carabiner
                }
            )
            .opacity(isBackgroundMode ? 0 : 1)
            .allowsHitTesting(!isBackgroundMode)
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
                // 다른 위치에 이미 장착된 키링인지 확인
                let existingPosition = selectedKeyrings.first { $0.value.id == keyring.id }?.key

                if let existingPos = existingPosition, existingPos != selectedPosition {
                    // 다른 위치에서 제거만 (현재 위치에 장착 X, 시트 유지)
                    selectedKeyrings[existingPos] = nil
                    keyringOrder.removeAll { $0 == existingPos }
                } else {
                    // 새 키링 선택 → 현재 위치에 장착, 시트 닫기
                    if selectedKeyrings[selectedPosition] != nil {
                        keyringOrder.removeAll { $0 == selectedPosition }
                    }
                    selectedKeyrings[selectedPosition] = keyring
                    keyringOrder.append(selectedPosition)
                    showKeyringSheet = false
                }
                sceneRefreshId = UUID()
            },
            onTapDeselect: { keyring in
                selectedKeyrings[selectedPosition] = nil
                keyringOrder.removeAll { $0 == selectedPosition }
                showKeyringSheet = false  // 시트 닫기
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
