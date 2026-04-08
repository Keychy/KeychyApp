//
//  KeyringVideoGenerator+Keyring.swift
//  Keychy
//
//  Created by 길지훈 on 1/15/26.
//

import Foundation
import UIKit
import Combine

// MARK: - Keyring Model Support

extension KeyringVideoGenerator {

    /// 키링 모델로부터 영상 생성 (컬렉션 뷰에서 사용)
    /// - Parameters:
    ///   - keyring: 키링 모델
    ///   - backgroundImage: 배경 이미지
    ///   - keyringScale: 키링 확대 배율
    /// - Returns: 생성된 영상 파일 URL
    func generateVideo(
        keyring: Keyring,
        backgroundImage: UIImage? = nil,
        keyringScale: CGFloat = 3.5
    ) async throws -> URL {
        // 이미지를 비동기로 먼저 다운로드 (메인스레드 블로킹 방지)
        let preloadedImage = await downloadBodyImage(from: keyring.bodyImage)

        // Keyring 모델을 래핑하는 어댑터 생성 (미리 로드된 이미지 전달)
        let adapter = KeyringAdapter(keyring: keyring, preloadedBodyImage: preloadedImage)

        // 기존 메서드 호출
        return try await generateVideo(
            viewModel: adapter,
            backgroundImage: backgroundImage,
            keyringScale: keyringScale
        )
    }

    /// 이미지 URL에서 비동기로 다운로드
    private func downloadBodyImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("[KeyringVideoGenerator] 이미지 다운로드 실패: \(error)")
            return nil
        }
    }
}

// MARK: - Keyring Adapter

/// Keyring 모델을 KeyringViewModelProtocol로 변환하는 어댑터
/// 영상 생성 시에만 사용되며, 최소한의 프로토콜 요구사항만 구현
@Observable
private class KeyringAdapter: KeyringViewModelProtocol {

    let keyring: Keyring
    private let preloadedBodyImage: UIImage?

    init(keyring: Keyring, preloadedBodyImage: UIImage?) {
        self.keyring = keyring
        self.preloadedBodyImage = preloadedBodyImage
    }

    // MARK: - KeyringViewModelProtocol 구현

    var nameText: String {
        get { keyring.name }
        set { }
    }

    var maxTextCount: Int { 10 }

    var memoText: String {
        get { keyring.memo ?? "" }
        set { }
    }

    var maxMemoCount: Int { 100 }

    var createdAt: Date {
        get { keyring.createdAt }
        set { }
    }

    var selectedTags: [String] {
        get { keyring.tags }
        set { }
    }

    var bodyImage: UIImage? {
        // 미리 로드된 이미지 반환 (비동기 다운로드 완료된 상태)
        preloadedBodyImage
    }

    var hookOffsetY: CGFloat {
        get { keyring.hookOffsetY ?? 0 }
        set { }
    }

    var chainLength: Int {
        keyring.chainLength
    }

    var templateId: String {
        keyring.selectedTemplate
    }

    var isGyroscope: Bool {
        keyring.isGyroscope
    }

    /// 렌티큘러 스타일 ID — 저장된 Keyring 모델의 값을 그대로 전달
    /// KeyringScene이 `KeyringAppearanceColor.from(id:)`로 복원하여 셰이더에 적용
    var shimmerColorId: String? {
        keyring.shimmerColorId
    }

    var borderColorId: String? {
        keyring.borderColorId
    }

    var availableCustomizingModes: [CustomizingMode] {
        [.effect]
    }

    var availableSounds: [Sound] { [] }
    var availableParticles: [Particle] { [] }
    var sortedAvailableSounds: [Sound] { [] }
    var sortedAvailableParticles: [Particle] { [] }

    var selectedSound: Sound? {
        get { nil }
        set { }
    }

    var selectedParticle: Particle? {
        get { nil }
        set { }
    }

    var customSoundURL: URL? {
        get { nil }
        set { }
    }

    var hasCustomSound: Bool { false }

    var downloadingItemIds: Set<String> {
        get { [] }
        set { }
    }

    var downloadProgress: [String: Double] {
        get { [:] }
        set { }
    }

    var soundId: String {
        get { keyring.soundId }
        set { }
    }

    var particleId: String {
        get { keyring.particleId }
        set { }
    }

    var effectSubject: PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never> {
        PassthroughSubject()
    }

    func updateSound(_ sound: Sound?) { }
    func updateParticle(_ particle: Particle?) { }
    func applyCustomSound(_ url: URL) { }
    func removeCustomSound() { }
    func fetchEffects() async { }
    func isOwned(soundId: String) -> Bool { false }
    func isOwned(particleId: String) -> Bool { false }
    func isInBundle(soundId: String) -> Bool { false }
    func isInBundle(particleId: String) -> Bool { false }
    func isInCache(soundId: String) -> Bool { false }
    func isInCache(particleId: String) -> Bool { false }
    func downloadSound(_ sound: Sound) async { }
    func downloadParticle(_ particle: Particle) async { }
    var savedKeyringDocumentId: String?
    var packagedPostOfficeId: String?
    var packagedShareLink: String?

    func resetCustomizingData() { }
    func resetInfoData() { }
    func resetAll() { }
}
