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
    
    /// 키링 선택 시트 오버레이
    var keyringSheetOverlay: some View {
        Group {
            if showSelectKeyringSheet {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(1)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showSelectKeyringSheet = false
                        }
                    }
                
                VStack(spacing: 18) {
                    Text("키링 선택")
                        .typography(.suit16B)
                        .foregroundStyle(.black100)
                    
                    if isKeyringSheetLoading {
                        VStack {
                            LoadingAlert(type: .short40, message: nil)
                                .padding(.vertical, 24)
                            Text("키링을 불러오고 있어요")
                                .typography(.suit15R)
                                .foregroundStyle(.black100)
                                .padding(.vertical, 15)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: screenHeight * (sheetHeightRatio - 0.08)) // 버튼 영역 제외한 대략 높이
                    } else if collectionVM.keyring.isEmpty {
                        VStack(spacing: 16) {
                            Image(.surprisedAlert)

                            Text("공방에서 키링을 만들어보세요.\n아직 만들어진 키링이 없어요.")
                                .typography(.suit15R)
                                .foregroundStyle(.black100)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(bundleVM.sortedKeyringsForSelection(selectedKeyrings: bundleVM.selectedKeyrings, selectedPosition: selectedPosition), id: \.self) { keyring in
                                    KeyringCell(
                                        keyring: keyring,
                                        isSelectedHere: bundleVM.selectedKeyrings[selectedPosition]?.id == keyring.id,
                                        isSelectedElsewhere: bundleVM.selectedKeyrings.values.contains { $0.id == keyring.id } && !(bundleVM.selectedKeyrings[selectedPosition]?.id == keyring.id),
                                        width: threeGridCellWidth,
                                        height: threeGridCellHeight,
                                        onTapSelect: {
                                            // 기존 있으면 순서 제거 후 교체
                                            if bundleVM.selectedKeyrings[selectedPosition] != nil {
                                                bundleVM.keyringOrder.removeAll { $0 == selectedPosition }
                                            }
                                            bundleVM.selectedKeyrings[selectedPosition] = keyring
                                            bundleVM.keyringOrder.append(selectedPosition)
                                            withAnimation(.easeInOut) {
                                                showSelectKeyringSheet = false
                                            }
                                            updateKeyringDataList()
                                        },
                                        onTapDeselect: {
                                            bundleVM.selectedKeyrings[selectedPosition] = nil
                                            bundleVM.keyringOrder.removeAll { $0 == selectedPosition }
                                            withAnimation(.easeInOut) {
                                                showSelectKeyringSheet = false
                                            }
                                            updateKeyringDataList()
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                }
                .padding(EdgeInsets(top: 30, leading: 20, bottom: 0, trailing: 20))
                .frame(maxWidth: .infinity)
                .frame(height: screenHeight * sheetHeightRatio)
                .glassEffect(.regular, in: .rect)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
                .shadow(radius: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom))
                .zIndex(2)
                
            }
        }
    }
    
}
