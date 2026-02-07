//
//  BundleEditView+SelectSheet.swift
//  Keychy
//
//  Created by 김서현 on 1/13/26.
//

import SwiftUI

extension BundleEditView {
    var selectItemSheetContent: some View {
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
    private var itemSheetContent: some View {
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
                    selectCarabiner = carabiner
                    showChangeCarabinerAlert = true
                }
            )
        }
    }
    
    /// 키링 선택 시트 (Create와 동일한 SwiftUI sheet 방식)
    var keyringSheetContent: some View {
        KeyringSelectionContent(
            searchText: $keyringSearchText,
            keyrings: sortedKeyringsForSelection,
            isLoading: isKeyringSheetLoading,
            gridColumns: gridColumns,
            cellWidth: threeGridCellWidth,
            cellHeight: threeGridCellHeight,
            isSelectedHere: { keyring in
                bundleVM.selectedKeyrings[selectedPosition]?.id == keyring.id
            },
            isSelectedElsewhere: { keyring in
                bundleVM.selectedKeyrings.values.contains { $0.id == keyring.id } &&
                !(bundleVM.selectedKeyrings[selectedPosition]?.id == keyring.id)
            },
            onTapSelect: { keyring in
                // 다른 위치에 이미 장착된 키링인지 확인
                let existingPosition = bundleVM.selectedKeyrings.first { $0.value.id == keyring.id }?.key

                if let existingPos = existingPosition, existingPos != selectedPosition {
                    // 다른 위치에서 제거만 (현재 위치에 장착 X, 시트 유지)
                    bundleVM.selectedKeyrings[existingPos] = nil
                    bundleVM.keyringOrder.removeAll { $0 == existingPos }
                } else {
                    // 새 키링 선택 → 현재 위치에 장착, 시트 닫기
                    if bundleVM.selectedKeyrings[selectedPosition] != nil {
                        bundleVM.keyringOrder.removeAll { $0 == selectedPosition }
                    }
                    bundleVM.selectedKeyrings[selectedPosition] = keyring
                    bundleVM.keyringOrder.append(selectedPosition)
                    showSelectKeyringSheet = false
                }
                updateKeyringDataList()
            },
            onTapDeselect: { keyring in
                bundleVM.selectedKeyrings[selectedPosition] = nil
                bundleVM.keyringOrder.removeAll { $0 == selectedPosition }
                showSelectKeyringSheet = false  // 시트 닫기
                updateKeyringDataList()
            }
        )
        .padding(.horizontal, 20)
        .presentationDetents([.fraction(0.45), .fraction(0.85)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 정렬된 키링 목록 (필터링은 KeyringSelectionContent에서 처리)
    var sortedKeyringsForSelection: [Keyring] {
        bundleVM.sortedKeyringsForSelection(
            selectedKeyrings: bundleVM.selectedKeyrings,
            selectedPosition: selectedPosition
        )
    }
}
