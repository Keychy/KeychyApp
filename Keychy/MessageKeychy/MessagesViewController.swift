//
//  MessagesViewController.swift
//  MessageKeychy
//
//  Created by 길지훈 on 2026-04-22.
//

import UIKit
import Messages

/// iMessage Extension 루트 뷰컨트롤러
///
/// Compact / Expanded 모두 `StickerCarouselVC` 하나로 표시한다.
/// 높이가 바뀔 뿐 VC 교체 없이 Auto Layout이 자동 대응한다.
/// - **[+] 탭**: `KeyringPickerVC`를 sheet로 표시 → 키링 선택 → APNG 생성
class MessagesViewController: MSMessagesAppViewController {

    private var carouselVC: StickerCarouselVC?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override func willBecomeActive(with conversation: MSConversation) {
        presentCarousel()
    }

    // MARK: - 캐러셀 (Compact / Expanded 공용)

    private func presentCarousel() {
        guard carouselVC == nil else {
            carouselVC?.reloadData()
            return
        }

        let vc = StickerCarouselVC()
        vc.delegate = self
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        carouselVC = vc
        vc.reloadData()
    }

    // MARK: - 키링 픽커 시트

    /// KeyringPickerVC를 풀스크린 시트로 표시
    private func presentPickerSheet() {
        let vc = KeyringPickerVC()
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }
}

// MARK: - StickerCarouselDelegate

extension MessagesViewController: StickerCarouselDelegate {

    func carouselDidTapAdd() {
        presentPickerSheet()
    }

    func carouselDidRemoveSticker(id: String) {
        // 캐러셀이 알아서 갱신하므로 추가 작업 불필요
    }
}

// MARK: - KeyringPickerDelegate

extension MessagesViewController: KeyringPickerDelegate {

    func pickerDidSelectKeyring(id: String) {
        dismiss(animated: true) { [weak self] in
            self?.carouselVC?.reloadData()
        }
    }
}
