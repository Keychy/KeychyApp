//
//  StickerCarouselVC.swift
//  MessageKeychy
//
//  Created by 길지훈 on 2026-04-22.
//

import UIKit
import Messages

/// Compact 모드 스티커 그리드
///
/// 상단에 `BIG | SMALL` 세그먼트 컨트롤을 제공한다.
/// - **SMALL**: `MSStickerBrowserViewController` (탭 전송, 200px, 500KB 이하)
/// - **BIG**: 가로 캐러셀 `UICollectionView` + `MSStickerView` (드래그 전송, 300px, 제한 없음)
protocol StickerCarouselDelegate: AnyObject {
    func carouselDidTapAdd()
}

class StickerCarouselVC: UIViewController {

    weak var delegate: StickerCarouselDelegate?

    // MARK: - 상단 바

    private let segmentedControl = UISegmentedControl(items: ["BIG", "SMALL"])
    private let addButton = UIButton(type: .custom)

    // MARK: - SMALL 모드 (기존 브라우저)

    private var browserVC: StickerBrowserChildVC!

    // MARK: - BIG 모드 (가로 캐러셀)

    private var bigCollectionView: UICollectionView!
    private var bigStickers: [(id: String, sticker: MSSticker)] = []
    private let bigCellID = "BigStickerCell"
    private let hintLabel = UILabel()
    private let emptyLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSegmentedControl()
        setupBrowser()
        setupBigCarousel()
        setupHintLabel()
        setupEmptyLabel()
        setupAddButton()
        updateVisibleView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Expanded ↔ Compact 전환 시 뷰 높이가 바뀌면 셀 크기 재계산
        bigCollectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - 데이터 갱신

    func reloadData() {
        // SMALL 오버사이즈(500KB 초과) 스티커 정리
        StickerDataManager.cleanOversizedStickers()

        let selectedIDs = StickerDataManager.loadSelectedIDs()

        // SMALL 로드
        browserVC.stickers = StickerManager.loadStickers(for: selectedIDs, size: .small)
        browserVC.stickerBrowserView.reloadData()

        // BIG 로드
        bigStickers = StickerManager.loadStickers(for: selectedIDs, size: .big)
        bigCollectionView.reloadData()
        updateEmptyState()
    }

    // MARK: - 세그먼트 컨트롤

    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0  // 기본: BIG
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
        ])
    }

    @objc private func segmentChanged() {
        updateVisibleView()
        // BIG 탭 전환 시 셀 레이아웃 강제 갱신 — 숨겨진 상태에서 로드된 셀의 프레임 보정
        if segmentedControl.selectedSegmentIndex == 0 {
            bigCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    /// 세그먼트 선택에 따라 SMALL/BIG 뷰 토글 및 힌트 카피 갱신
    private func updateVisibleView() {
        let isBig = segmentedControl.selectedSegmentIndex == 0
        browserVC.view.isHidden = isBig
        bigCollectionView.isHidden = !isBig
        // BIG은 500KB 초과로 탭 전송 불가 → 꾹 눌러 드래그만 가능
        // SMALL은 탭/peel 둘 다 지원
        hintLabel.text = isBig
            ? "꾹 눌러서 말풍선에 붙여보세요!"
            : "탭하거나 꾹 눌러서 보내세요"
        updateEmptyState()
    }

    // MARK: - SMALL 브라우저 Setup

    /// MSStickerBrowserViewController를 자식 VC로 추가
    /// Apple 프레임워크가 스티커 탭/필 제스처를 네이티브로 처리
    private func setupBrowser() {
        browserVC = StickerBrowserChildVC()
        addChild(browserVC)
        browserVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(browserVC.view)
        browserVC.didMove(toParent: self)

        NSLayoutConstraint.activate([
            browserVC.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            browserVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browserVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            browserVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - BIG 캐러셀 Setup

    private func setupBigCarousel() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        // 음수 간격으로 카드 겹침 효과
        layout.minimumLineSpacing = -40
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        bigCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        bigCollectionView.backgroundColor = .clear
        bigCollectionView.showsHorizontalScrollIndicator = false
        bigCollectionView.decelerationRate = .fast
        // peel 제스처: 터치를 즉시 전달하되, 스와이프 감지 시 취소 허용
        bigCollectionView.delaysContentTouches = false
        bigCollectionView.canCancelContentTouches = true
        bigCollectionView.dataSource = self
        bigCollectionView.delegate = self
        bigCollectionView.register(BigStickerCell.self, forCellWithReuseIdentifier: bigCellID)
        bigCollectionView.translatesAutoresizingMaskIntoConstraints = false
        bigCollectionView.isHidden = true

        view.addSubview(bigCollectionView)
        NSLayoutConstraint.activate([
            bigCollectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            bigCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bigCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bigCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -28),
        ])
    }

    // MARK: - 빈 상태 안내

    private func setupEmptyLabel() {
        emptyLabel.text = "+ 버튼을 눌러 스티커를 추가해보세요!"
        emptyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        emptyLabel.textColor = .tertiaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func updateEmptyState() {
        let isBig = segmentedControl.selectedSegmentIndex == 0
        let isEmpty = isBig ? bigStickers.isEmpty : (browserVC?.stickers.isEmpty ?? true)
        emptyLabel.isHidden = !isEmpty
        hintLabel.isHidden = isEmpty
    }

    // MARK: - 안내 라벨

    private func setupHintLabel() {
        // text는 updateVisibleView()에서 모드별로 설정됨
        hintLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center
        hintLabel.isHidden = true
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -14),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - [+] 버튼

    /// 우측 상단 [+] 플로팅 버튼
    private func setupAddButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: config),
            for: .normal
        )
        addButton.tintColor = .white
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 18
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.15
        addButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addButton.layer.shadowRadius = 4
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            addButton.widthAnchor.constraint(equalToConstant: 36),
            addButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    @objc private func addTapped() {
        delegate?.carouselDidTapAdd()
    }
}

// MARK: - BIG 캐러셀 DataSource / Delegate

extension StickerCarouselVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        bigStickers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bigCellID, for: indexPath) as! BigStickerCell
        cell.configure(with: bigStickers[indexPath.item].sticker)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = min(collectionView.bounds.height, 200)
        return CGSize(width: side, height: side)
    }
}

// MARK: - BigStickerCell (MSStickerView 래퍼)

/// BIG 모드 셀: MSStickerView를 감싸서 꾹 눌러 드래그(peel) 전송을 지원
///
/// MSStickerView는 Apple 프레임워크가 제공하는 뷰로,
/// 내장된 롱프레스 제스처로 스티커를 드래그 전송할 수 있다.
/// 탭 전송과 달리 500KB 제한이 적용되지 않는다.
private class BigStickerCell: UICollectionViewCell {

    private var stickerView: MSStickerView?
    /// 스티커를 화면 가장자리에서 띄우기 위한 내부 여백
    private let stickerInset: CGFloat = 16

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// configure 시점에 contentView.bounds가 .zero일 수 있으므로
    /// layoutSubviews에서 MSStickerView 프레임을 확정한다.
    /// 프레임이 0이면 peel 제스처의 터치 영역이 잡히지 않아 드래그가 안 된다.
    override func layoutSubviews() {
        super.layoutSubviews()
        stickerView?.frame = contentView.bounds.insetBy(dx: stickerInset, dy: stickerInset)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stickerView?.stopAnimating()
        stickerView?.removeFromSuperview()
        stickerView = nil
    }

    func configure(with sticker: MSSticker) {
        let sv = MSStickerView(frame: contentView.bounds.insetBy(dx: stickerInset, dy: stickerInset), sticker: sticker)
        sv.startAnimating()
        contentView.addSubview(sv)
        stickerView = sv
    }
}

// MARK: - MSStickerBrowserViewController 자식 VC

/// Apple의 MSStickerBrowserViewController를 그대로 사용
/// → 스티커 탭/필 제스처가 프레임워크 레벨에서 보장됨
class StickerBrowserChildVC: MSStickerBrowserViewController {

    var stickers: [(id: String, sticker: MSSticker)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        stickerBrowserView.backgroundColor = .systemBackground
    }

    override func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        stickers.count
    }

    override func stickerBrowserView(
        _ stickerBrowserView: MSStickerBrowserView,
        stickerAt index: Int
    ) -> MSSticker {
        stickers[index].sticker
    }
}
