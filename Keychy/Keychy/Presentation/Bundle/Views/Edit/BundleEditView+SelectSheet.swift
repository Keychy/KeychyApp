//
//  BundleEditView+SelectSheet.swift
//  Keychy
//
//  Created by 김서현 on 1/13/26.
//

import SwiftUI

extension BundleEditView {
    var selectItemSheetContent: some View {
        Group {
            // 배경 시트
            VStack(spacing: 0) {
                Spacer()
                BundleSheetToggleButtons(
                    showBackgroundSheet: $showBackgroundSheet,
                    showCarabinerSheet: $showCarabinerSheet
                )
                DraggableSheet(
                    sheetHeight: $sheetHeight,
                    content: SelectBackgroundSheet(
                        viewModel: bundleVM,
                        selectedBG: bundleVM.newSelectedBackground,
                        onBackgroundTap: { bg in
                            bundleVM.newSelectedBackground = bg
                        }
                    )
                )
            }
            .opacity(showBackgroundSheet ? 1 : 0)

            // 카라비너 시트
            VStack(spacing: 0) {
                Spacer()
                BundleSheetToggleButtons(
                    showBackgroundSheet: $showBackgroundSheet,
                    showCarabinerSheet: $showCarabinerSheet
                )
                DraggableSheet(
                    sheetHeight: $sheetHeight,
                    content: SelectCarabinerSheet(
                        viewModel: bundleVM,
                        selectedCarabiner: bundleVM.newSelectedCarabiner,
                        onCarabinerTap: { carabiner in
                            selectCarabiner = carabiner
                            showChangeCarabinerAlert = true
                        }
                    )
                )
            }
            .opacity(showCarabinerSheet ? 1 : 0)
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
                        VStack {
                            Image(.emptyViewIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 77)
                            Text("공방에서 키링을 만들 수 있어요")
                                .typography(.suit15R)
                                .foregroundStyle(.black100)
                                .padding(.vertical, 15)
                        }
                        .padding(.bottom, 77)
                        .padding(.top, 62)
                        .frame(maxWidth: .infinity)
                        
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
