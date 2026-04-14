//
//  LenticularVM+Style.swift
//  Keychy
//
//  Created by 길지훈 on 2026-04-09.
//
//  렌티큘러 시머/테두리 프리셋 선택 + 카트/소유/가격 조회 + 틴트 색상 변환
//  StyleSelectorView가 호출하는 모든 비즈니스 로직을 담당.
//

import SwiftUI

extension LenticularVM {
    // MARK: - 소유/가격 조회
    /// View가 StylePresetManager를 직접 호출하지 않도록 VM이 중계

    func isShimmerOwned(_ preset: KeyringStylePreset) -> Bool {
        StylePresetManager.shared.isOwned(
            preset: preset, in: .shimmer, userManager: userManager
        )
    }

    func isBorderOwned(_ preset: KeyringStylePreset) -> Bool {
        StylePresetManager.shared.isOwned(
            preset: preset, in: .border, userManager: userManager
        )
    }

    func shimmerPrice(_ preset: KeyringStylePreset) -> Int {
        StylePresetManager.shared.price(for: preset, in: .shimmer)
    }

    func borderPrice(_ preset: KeyringStylePreset) -> Int {
        StylePresetManager.shared.price(for: preset, in: .border)
    }

    // MARK: - 시머/테두리 선택 (3-way 분기)
    /// 시머 프리셋 선택
    /// - 무료 or 보유 → 즉시 적용 + 카트에서 시머 제거
    /// - 미보유 유료 + 이미 선택됨 → 선택 해제 (silver로 폴백)
    /// - 미보유 유료 + 미선택 → 카트 추가 + 미리보기 적용
    func selectShimmerEffect(
        preset: KeyringStylePreset,
        cartItems: Binding<[EffectItem]>
    ) {
        let isUsable = preset.isFree || isShimmerOwned(preset)
        let isCurrentlySelected = selectedShimmerEffect.activePreset == preset

        if isUsable {
            updateShimmerEffect(.preset(preset))
            cartItems.wrappedValue.removeAll { $0.type == .shimmerEffect }
        } else if isCurrentlySelected {
            updateShimmerEffect(.preset(.silver))
            cartItems.wrappedValue.removeAll { $0.type == .shimmerEffect }
        } else {
            cartItems.wrappedValue.removeAll { $0.type == .shimmerEffect }
            cartItems.wrappedValue.append(
                EffectItem(shimmerEffect: preset, price: shimmerPrice(preset))
            )
            updateShimmerEffect(.preset(preset))
        }
    }

    /// 테두리 프리셋 선택 (시머와 동일한 3-way 분기)
    func selectBorderEffect(
        preset: KeyringStylePreset,
        cartItems: Binding<[EffectItem]>
    ) {
        let isUsable = preset.isFree || isBorderOwned(preset)
        let isCurrentlySelected = selectedBorderEffect.activePreset == preset

        if isUsable {
            updateBorderEffect(.preset(preset))
            cartItems.wrappedValue.removeAll { $0.type == .borderEffect }
        } else if isCurrentlySelected {
            updateBorderEffect(.preset(.silver))
            cartItems.wrappedValue.removeAll { $0.type == .borderEffect }
        } else {
            cartItems.wrappedValue.removeAll { $0.type == .borderEffect }
            cartItems.wrappedValue.append(
                EffectItem(borderEffect: preset, price: borderPrice(preset))
            )
            updateBorderEffect(.preset(preset))
        }
    }

    // MARK: - 틴트 색상 변환 (Color ↔ 셰이더 RGB)

    /// ColorPicker getter용: 셰이더 RGB → SwiftUI Color
    func shimmerTintColor() -> Color {
        let c = selectedShimmerEffect.shaderColor
        return Color(red: Double(c.r), green: Double(c.g), blue: Double(c.b))
    }

    func borderTintColor() -> Color {
        let c = selectedBorderEffect.shaderColor
        return Color(red: Double(c.r), green: Double(c.g), blue: Double(c.b))
    }

    /// ColorPicker setter용: Color → UIColor → 셰이더 RGB → VM 업데이트
    /// hologram은 색상 변경 불가 (셰이더가 자체 무지개 그라데이션 사용)
    func updateShimmerTint(color: Color) {
        let mode = selectedShimmerEffect.activePreset
        guard mode != .hologram else { return }
        let c = UIColor(color).rgbComponents
        updateShimmerEffect(.customTint(mode: mode, r: c.r, g: c.g, b: c.b))
    }

    func updateBorderTint(color: Color) {
        let mode = selectedBorderEffect.activePreset
        guard mode != .hologram else { return }
        let c = UIColor(color).rgbComponents
        updateBorderEffect(.customTint(mode: mode, r: c.r, g: c.g, b: c.b))
    }
}
