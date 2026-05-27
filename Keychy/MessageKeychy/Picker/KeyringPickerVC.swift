//
//  KeyringPickerVC.swift
//  MessageKeychy
//
//  Created by 길지훈 on 2026-04-22.
//

import UIKit

/// Expanded 모드에서 전체 키링 목록을 3열 그리드로 보여주는 뷰컨트롤러
///
/// 사용자가 키링을 탭하면 bodyImage를 다운로드 후 APNG를 생성하고,
/// 완료되면 delegate를 통해 Compact 모드로 복귀시킨다.
protocol KeyringPickerDelegate: AnyObject {
    /// 키링 선택 + APNG 생성 완료 → Compact 복귀
    func pickerDidSelectKeyring()
}

class KeyringPickerVC: UIViewController {

    weak var delegate: KeyringPickerDelegate?

    private var keyrings: [StickerKeyring] = []
    private var selectedIDs: Set<String> = []
    private var searchQuery: String = ""
    private let searchBar = UISearchBar()
    private var collectionView: UICollectionView!
    private let cellID = "KeyringPickerCell"

    // 로딩 오버레이 (스티커 생성 중 표시)
    private let loadingOverlay = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()

    // 검색 결과 0건 안내
    private let emptyResultLabel = UILabel()

    /// 검색어 적용 후 실제 표시할 키링 배열
    private var displayedKeyrings: [StickerKeyring] {
        guard !searchQuery.isEmpty else { return keyrings }
        // localizedStandardContains: 대소문자/악센트/한글 정규화 무시
        return keyrings.filter { $0.name.localizedStandardContains(searchQuery) }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSearchBar()
        setupCollectionView()
        setupEmptyResultLabel()
        setupLoadingOverlay()
        loadData()
    }

    // MARK: - 데이터

    private func loadData() {
        // 선택 ID를 먼저 로드해야 정렬에서 참조 가능
        selectedIDs = Set(StickerDataManager.loadSelectedIDs())
        keyrings = StickerDataManager.loadAllKeyrings()
            .sorted { lhs, rhs in
                let lhsSelected = selectedIDs.contains(lhs.id)
                let rhsSelected = selectedIDs.contains(rhs.id)
                // 1순위: 미선택이 위로
                if lhsSelected != rhsSelected { return !lhsSelected }
                // 2순위: 같은 그룹 내에선 최신순
                return lhs.createdAt > rhs.createdAt
            }
        collectionView.reloadData()
    }

    // MARK: - Setup

    private func setupSearchBar() {
        searchBar.placeholder = "키링 이름 검색"
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        collectionView.register(KeyringPickerCell.self, forCellWithReuseIdentifier: cellID)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - 검색 결과 0건 안내

    private func setupEmptyResultLabel() {
        emptyResultLabel.text = "검색 결과가 없어요"
        emptyResultLabel.font = .systemFont(ofSize: 14, weight: .medium)
        emptyResultLabel.textColor = .tertiaryLabel
        emptyResultLabel.textAlignment = .center
        emptyResultLabel.isHidden = true
        emptyResultLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(emptyResultLabel)
        NSLayoutConstraint.activate([
            emptyResultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyResultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    /// 검색어가 있고 결과가 0건일 때만 안내 라벨 표시
    private func updateEmptyResultVisibility() {
        emptyResultLabel.isHidden = !(searchQuery.isEmpty == false && displayedKeyrings.isEmpty)
    }

    // MARK: - 로딩 오버레이

    /// iOS 시스템 alert 톤 — 살짝 어두운 backdrop + 중앙 카드
    /// 터치 차단 효과로 생성 중 중복 탭 방지
    private func setupLoadingOverlay() {
        loadingOverlay.isHidden = true
        loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false

        // 중앙 카드 (시스템 블러 + 둥근 모서리)
        let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        card.layer.cornerRadius = 14
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(card)

        loadingIndicator.color = .label
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(loadingIndicator)

        loadingLabel.text = "스티커 생성 중..."
        loadingLabel.font = .systemFont(ofSize: 14, weight: .medium)
        loadingLabel.textColor = .label
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(loadingLabel)

        view.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            // backdrop은 시트 전체
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // 카드는 중앙 고정 크기 (alert 스타일)
            card.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 160),
            card.heightAnchor.constraint(equalToConstant: 110),

            loadingIndicator.centerXAnchor.constraint(equalTo: card.contentView.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 22),

            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 12),
            loadingLabel.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 8),
            loadingLabel.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -8),
        ])
    }

    private func showLoadingOverlay() {
        loadingOverlay.isHidden = false
        loadingIndicator.startAnimating()
        view.bringSubviewToFront(loadingOverlay)
    }

    private func hideLoadingOverlay() {
        loadingOverlay.isHidden = true
        loadingIndicator.stopAnimating()
    }
}

// MARK: - UISearchBarDelegate

extension KeyringPickerVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchQuery = searchText
        collectionView.reloadData()
        updateEmptyResultVisibility()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UICollectionViewDataSource

extension KeyringPickerVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedKeyrings.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! KeyringPickerCell
        let keyring = displayedKeyrings[indexPath.item]
        let isSelected = selectedIDs.contains(keyring.id)
        cell.configure(keyring: keyring, isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension KeyringPickerVC: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 3열 그리드: (화면 폭 - 좌우 패딩 - 셀 간격) / 3
        let totalSpacing: CGFloat = 16 * 2 + 8 * 2
        let width = floor((collectionView.bounds.width - totalSpacing) / 3)
        return CGSize(width: width, height: width + 28)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let keyring = displayedKeyrings[indexPath.item]

        // 이미 선택된 키링이면 무시
        guard !selectedIDs.contains(keyring.id) else { return }

        // 시트 전체 로딩 오버레이 — 생성 중 중복 탭 차단
        showLoadingOverlay()

        // Task.detached: caller(MainActor) 액터 상속 안 함 → 진짜 백그라운드 실행 보장
        // 일반 Task { }는 MainActor를 상속해 동기 CPU 작업이 메인 스레드를 점유할 수 있음
        Task.detached(priority: .userInitiated) {
            let results = await StickerGenerator.generateStickers(for: keyring, sizes: [.small, .big])
            let isSuccess = results[.small] != nil

            // 메타데이터 저장은 self(VC) 생존 여부와 분리 — 시트가 swipe로 닫혀도
            // 백그라운드 합성 결과가 selected_stickers.json에 반영되어 손실 없음
            // (다음 카루셀 진입 시 새 스티커가 자동으로 나타남)
            if isSuccess {
                StickerDataManager.addSticker(id: keyring.id)
            }

            // UI 업데이트는 self가 살아 있을 때만 — 없으면 어차피 사용자가 시트를 떠남
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.hideLoadingOverlay()

                guard isSuccess else {
                    if let cell = self.collectionView.cellForItem(at: indexPath) as? KeyringPickerCell {
                        cell.shake()
                    }
                    return
                }

                self.selectedIDs.insert(keyring.id)
                self.collectionView.reloadItems(at: [indexPath])
                self.delegate?.pickerDidSelectKeyring()
            }
        }
    }
}

// MARK: - KeyringPickerCell

private class KeyringPickerCell: UICollectionViewCell {

    private let thumbnailView = UIImageView()
    private let nameLabel = UILabel()
    private let checkmarkView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    /// 현재 셀에 표시 중인 키링 ID — 비동기 로드 완료 시 셀 재사용 여부 검증용
    private var currentKeyringID: String?

    /// 클래스 단위 메모리 캐시 — 메모리 압박 시 자동 evict, 200개 캡
    private static let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        return cache
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = nil
        nameLabel.text = nil
        checkmarkView.isHidden = true
        loadingIndicator.stopAnimating()
        currentKeyringID = nil
    }

    func configure(keyring: StickerKeyring, isSelected: Bool) {
        nameLabel.text = keyring.name
        checkmarkView.isHidden = !isSelected
        contentView.alpha = isSelected ? 0.5 : 1.0
        currentKeyringID = keyring.id

        // 캐시 히트 → 즉시 표시
        if let cached = Self.thumbnailCache.object(forKey: keyring.id as NSString) {
            thumbnailView.image = cached
            return
        }

        // 로드 전 플레이스홀더
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
        thumbnailView.image = UIImage(systemName: "photo", withConfiguration: config)
        thumbnailView.tintColor = .systemGray3

        // 백그라운드 디스크 I/O — 메인 스레드 hitch 방지
        let targetID = keyring.id
        Task.detached(priority: .userInitiated) {
            guard let url = StickerDataManager.thumbnailURL(for: targetID),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else { return }

            Self.thumbnailCache.setObject(image, forKey: targetID as NSString)

            await MainActor.run { [weak self] in
                // 비동기 로드 도중 셀이 재사용되어 다른 키링을 표시 중이면 무시
                guard let self = self, self.currentKeyringID == targetID else { return }
                self.thumbnailView.image = image
            }
        }
    }

    func showLoading() {
        loadingIndicator.startAnimating()
        contentView.isUserInteractionEnabled = false
        contentView.alpha = 0.6
    }

    func hideLoading() {
        loadingIndicator.stopAnimating()
        contentView.isUserInteractionEnabled = true
        contentView.alpha = 1.0
    }

    /// 생성 실패 시 셀 흔들기 애니메이션
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -3, 3, 0]
        layer.add(animation, forKey: "shake")
    }

    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        // 썸네일
        thumbnailView.contentMode = .scaleAspectFit
        thumbnailView.clipsToBounds = true
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailView)

        // 이름 라벨
        nameLabel.font = .systemFont(ofSize: 11, weight: .medium)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .label
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        // 체크마크 (선택 상태)
        let checkConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkConfig)
        checkmarkView.tintColor = .systemBlue
        checkmarkView.isHidden = true
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkmarkView)

        // 로딩 인디케이터
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            thumbnailView.bottomAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -4),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            nameLabel.heightAnchor.constraint(equalToConstant: 16),

            checkmarkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),

            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
        ])
    }
}
