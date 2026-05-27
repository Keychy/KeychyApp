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

/// BIG 모드의 레이아웃 스타일
/// - `carousel`: 가로 겹침 캐러셀 (Compact 프레젠테이션)
/// - `grid`: 2열 세로 그리드 (Expanded 프레젠테이션)
enum BigLayoutStyle {
    case carousel
    case grid
}

class StickerCarouselVC: UIViewController {

    weak var delegate: StickerCarouselDelegate?

    // MARK: - 상단 바

    private let segmentedControl = UISegmentedControl(items: ["BIG", "SMALL"])
    private let addButton = UIButton(type: .custom)
    private let editButton = UIButton(type: .system)

    /// 편집 모드 (Expanded + BIG 일 때만 진입 가능)
    /// true일 때 각 셀에 X 뱃지가 노출되고 peel 제스처는 비활성화됨
    private var isEditMode: Bool = false {
        didSet { applyEditMode() }
    }

    // MARK: - SMALL 모드 (기존 브라우저)

    private var browserVC: StickerBrowserChildVC!

    // MARK: - BIG 모드 (가로 캐러셀 / 2열 그리드)

    private var bigCollectionView: UICollectionView!
    private var bigStickers: [(id: String, sticker: MSSticker)] = []
    private let bigCellID = "BigStickerCell"
    private var bigLayoutStyle: BigLayoutStyle = .carousel
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
        setupEditButton()
        updateVisibleView()
        updateEditButtonVisibility()
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
        updateEditButtonVisibility()
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
        // BIG은 peel만 가능하고 상단 30% 고리 영역만 잡히도록 제한 → 카피로 명시
        // SMALL은 탭/peel 둘 다 지원
        hintLabel.text = isBig
            ? "고리를 꾹 눌러서 말풍선에 붙여보세요"
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
        bigCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCarouselLayout())
        bigCollectionView.backgroundColor = .clear
        bigCollectionView.showsHorizontalScrollIndicator = false
        bigCollectionView.showsVerticalScrollIndicator = false
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

    // MARK: - 레이아웃 팩토리

    /// Compact용: 가로 겹침 캐러셀
    private func makeCarouselLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = -40  // 음수 간격으로 카드 겹침 효과
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return layout
    }

    /// Expanded용: 2열 세로 그리드
    private func makeGridLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return layout
    }

    // MARK: - 프레젠테이션 스타일 전환

    /// MessagesViewController가 Compact ↔ Expanded 전환 시 호출
    func applyPresentation(_ style: MSMessagesAppPresentationStyle) {
        let newStyle: BigLayoutStyle = (style == .expanded) ? .grid : .carousel
        guard newStyle != bigLayoutStyle else { return }
        bigLayoutStyle = newStyle

        let layout = (newStyle == .grid) ? makeGridLayout() : makeCarouselLayout()
        bigCollectionView.setCollectionViewLayout(layout, animated: true)
        updateEditButtonVisibility()
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

    // MARK: - 편집 버튼

    /// "편집" / "완료" 토글 버튼 — Expanded + BIG 일 때만 노출
    private func setupEditButton() {
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        editButton.setTitle("편집", for: .normal)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(editButton)
        NSLayoutConstraint.activate([
            editButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -12),
        ])
    }

    @objc private func editTapped() {
        isEditMode.toggle()
    }

    /// 편집 모드 진입/종료 시 셀과 상단 버튼 상태 동기화
    private func applyEditMode() {
        editButton.setTitle(isEditMode ? "완료" : "편집", for: .normal)
        addButton.isHidden = isEditMode  // 편집 중엔 추가 불가
        for cell in bigCollectionView.visibleCells {
            (cell as? BigStickerCell)?.isEditing = isEditMode
        }
    }

    /// Expanded + BIG 일 때만 편집 버튼 노출
    /// 그 외 상황에서 편집 중이었다면 자동 종료
    private func updateEditButtonVisibility() {
        let isBig = segmentedControl.selectedSegmentIndex == 0
        let isExpanded = (bigLayoutStyle == .grid)
        let shouldShow = isBig && isExpanded
        editButton.isHidden = !shouldShow
        if !shouldShow && isEditMode {
            isEditMode = false
        }
    }

    // MARK: - 삭제 확인

    /// X 뱃지 탭 시 확인 alert → 삭제 → reload
    private func confirmDelete(id: String) {
        let alert = UIAlertController(
            title: "스티커 제거",
            message: "이 스티커를 카루셀에서 제거할까요?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "제거", style: .destructive) { [weak self] _ in
            StickerDataManager.removeSticker(id: id)
            self?.reloadData()
            // 모두 제거됐으면 편집 모드 자동 종료
            if self?.bigStickers.isEmpty == true {
                self?.isEditMode = false
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - BIG 캐러셀 DataSource / Delegate

extension StickerCarouselVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        bigStickers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bigCellID, for: indexPath) as! BigStickerCell
        let item = bigStickers[indexPath.item]
        cell.configure(with: item.sticker)
        cell.isEditing = isEditMode
        cell.onDelete = { [weak self] in
            self?.confirmDelete(id: item.id)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch bigLayoutStyle {
        case .carousel:
            // 가로 캐러셀: 뷰 높이 기준 정사각형 (최대 200pt)
            let side = min(collectionView.bounds.height, 200)
            return CGSize(width: side, height: side)
        case .grid:
            // 2열 그리드: (전체 폭 - 좌우 sectionInset - 셀 간격) / 2
            let totalSpacing: CGFloat = 16 * 2 + 12
            let side = floor((collectionView.bounds.width - totalSpacing) / 2)
            return CGSize(width: side, height: side)
        }
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
    private let deleteButton = UIButton(type: .custom)
    /// 스티커를 화면 가장자리에서 띄우기 위한 내부 여백
    private let stickerInset: CGFloat = 16

    /// peel(꾹 눌러 드래그) 가능 영역을 상단 N%로 제한
    ///
    /// MSStickerView는 peel 시작 시점의 터치 좌표를 anchor로 사용해
    /// 메시지에 스티커가 그 위치 기준으로 박힌다.
    /// 키링은 캐러비너(상단)에서 매달리는 구조라 상단만 잡혀야 자연스럽게
    /// 매달린 형태로 메시지에 들어간다. 하단 터치는 무시되어
    /// 컬렉션뷰의 스크롤 제스처로 통과된다.
    private static let peelableTopRatio: CGFloat = 0.30

    /// 편집 모드 — true일 때 X 뱃지 노출 + peel 제스처 차단
    var isEditing: Bool = false {
        didSet { applyEditState() }
    }

    /// X 뱃지 탭 콜백
    var onDelete: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        setupDeleteButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupDeleteButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        deleteButton.tintColor = .systemRed
        // 키링 위에서 가독성 확보 위해 흰 배경 원
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 14
        deleteButton.layer.shadowColor = UIColor.black.cgColor
        deleteButton.layer.shadowOpacity = 0.2
        deleteButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        deleteButton.layer.shadowRadius = 2
        deleteButton.isHidden = true
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    @objc private func deleteTapped() {
        onDelete?()
    }

    private func applyEditState() {
        deleteButton.isHidden = !isEditing
        if isEditing {
            startWiggle()
        } else {
            layer.removeAnimation(forKey: "wiggle")
        }
    }

    /// iOS 홈화면 스타일의 미세한 흔들림 — 편집 가능 상태 시각화
    private func startWiggle() {
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = [-0.02, 0.02, -0.02]
        animation.duration = 0.25
        animation.repeatCount = .infinity
        layer.add(animation, forKey: "wiggle")
    }

    /// configure 시점에 contentView.bounds가 .zero일 수 있으므로
    /// layoutSubviews에서 MSStickerView 프레임을 확정한다.
    /// 프레임이 0이면 peel 제스처의 터치 영역이 잡히지 않아 드래그가 안 된다.
    override func layoutSubviews() {
        super.layoutSubviews()
        stickerView?.frame = contentView.bounds.insetBy(dx: stickerInset, dy: stickerInset)
    }

    /// - 편집 모드: deleteButton만 인터랙티브, 나머지 영역은 nil → 스크롤로 패스
    /// - 일반 모드: 상단 30%만 peel 가능
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isEditing {
            return deleteButton.frame.contains(point) ? deleteButton : nil
        }
        guard let sv = stickerView else {
            return super.hitTest(point, with: event)
        }
        let peelable = CGRect(
            x: sv.frame.minX,
            y: sv.frame.minY,
            width: sv.frame.width,
            height: sv.frame.height * Self.peelableTopRatio
        )
        return peelable.contains(point) ? super.hitTest(point, with: event) : nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stickerView?.stopAnimating()
        stickerView?.removeFromSuperview()
        stickerView = nil
        isEditing = false
        onDelete = nil
    }

    func configure(with sticker: MSSticker) {
        let sv = MSStickerView(frame: contentView.bounds.insetBy(dx: stickerInset, dy: stickerInset), sticker: sticker)
        sv.startAnimating()
        contentView.addSubview(sv)
        // deleteButton이 항상 sticker 위에 오도록
        contentView.bringSubviewToFront(deleteButton)
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
