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
    func pickerDidSelectKeyring(id: String)
}

class KeyringPickerVC: UIViewController {

    weak var delegate: KeyringPickerDelegate?

    private var keyrings: [StickerKeyring] = []
    private var selectedIDs: Set<String> = []
    private var collectionView: UICollectionView!
    private let cellID = "KeyringPickerCell"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupCollectionView()
        loadData()
    }

    // MARK: - 데이터

    private func loadData() {
        keyrings = StickerDataManager.loadAllKeyrings()
            .sorted { $0.createdAt > $1.createdAt }
        selectedIDs = Set(StickerDataManager.loadSelectedIDs())
        collectionView.reloadData()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(KeyringPickerCell.self, forCellWithReuseIdentifier: cellID)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension KeyringPickerVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        keyrings.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! KeyringPickerCell
        let keyring = keyrings[indexPath.item]
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
        let keyring = keyrings[indexPath.item]

        // 이미 선택된 키링이면 무시
        guard !selectedIDs.contains(keyring.id) else { return }

        // 로딩 표시
        guard let cell = collectionView.cellForItem(at: indexPath) as? KeyringPickerCell else { return }
        cell.showLoading()

        Task {
            // 다운로드/프레임 합성 1회 공유 + SMALL/BIG 인코딩만 각각
            let results = await StickerGenerator.generateStickers(for: keyring, sizes: [.small, .big])

            await MainActor.run {
                cell.hideLoading()

                // SMALL이 필수 — 실패 시 전체 실패 처리 (탭 전송 불가)
                guard results[.small] != nil else {
                    cell.shake()
                    return
                }

                // 선택 목록에 추가
                StickerDataManager.addSticker(id: keyring.id)
                selectedIDs.insert(keyring.id)
                collectionView.reloadItems(at: [indexPath])

                delegate?.pickerDidSelectKeyring(id: keyring.id)
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
    }

    func configure(keyring: StickerKeyring, isSelected: Bool) {
        nameLabel.text = keyring.name
        checkmarkView.isHidden = !isSelected
        contentView.alpha = isSelected ? 0.5 : 1.0

        // 썸네일 로드
        if let url = StickerDataManager.thumbnailURL(for: keyring.id),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            thumbnailView.image = image
        } else {
            // 썸네일 없으면 SF Symbol 플레이스홀더
            let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
            thumbnailView.image = UIImage(systemName: "photo", withConfiguration: config)
            thumbnailView.tintColor = .systemGray3
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
