//
//  CrossStitchVM.swift
//  Keychy
//
//  Created by Jini on 3/10/26.
//

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class CrossStitchVM: KeyringViewModelProtocol {
    // MARK: - Template Data (Firebase)
    var template: KeyringTemplate?
    var isLoadingTemplate = false

    // MARK: - Effect Data (Firebase)
    var availableSounds: [Sound] = []
    var availableParticles: [Particle] = []

    /// 정렬된 사운드 리스트
    var sortedAvailableSounds: [Sound] {
        availableSounds.sorted { sound1, sound2 in
            guard let id1 = sound1.id, let id2 = sound2.id else { return false }

            let downloaded1 = isInBundle(soundId: id1) || isInCache(soundId: id1)
            let downloaded2 = isInBundle(soundId: id2) || isInCache(soundId: id2)

            let priority1 = getSortPriority(
                isFree: sound1.isFree,
                isDownloaded: downloaded1
            )
            let priority2 = getSortPriority(
                isFree: sound2.isFree,
                isDownloaded: downloaded2
            )

            return priority1 < priority2
        }
    }

    /// 정렬된 파티클 리스트
    var sortedAvailableParticles: [Particle] {
        availableParticles.sorted { particle1, particle2 in
            guard let id1 = particle1.id, let id2 = particle2.id else { return false }

            let downloaded1 = isInBundle(particleId: id1) || isInCache(particleId: id1)
            let downloaded2 = isInBundle(particleId: id2) || isInCache(particleId: id2)

            let priority1 = getSortPriority(
                isFree: particle1.isFree,
                isDownloaded: downloaded1
            )
            let priority2 = getSortPriority(
                isFree: particle2.isFree,
                isDownloaded: downloaded2
            )

            return priority1 < priority2
        }
    }

    var selectedSound: Sound? = nil
    var selectedParticle: Particle? = nil

    // MARK: - Custom Sound (녹음)
    var customSoundURL: URL? = nil

    // MARK: - Download State
    var downloadingItemIds: Set<String> = []
    var downloadProgress: [String: Double] = [:]

    // MARK: - Scene 전달용 ID
    var soundId: String = "none"
    var particleId: String = "none"

    // MARK: - Combine Bridge
    let effectSubject = PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never>()

    // MARK: - UserManager
    var userManager: UserManager

    // MARK: - Stitch Grid Data
    /// 선택된 그리드 사이즈
    var gridSize: Int = 16
    
    /// gridSize x gridSize 스티치 그리드 (기본값: .white)
    var stitchGrid: [[StitchColor]] = Array(
        repeating: Array(repeating: .white, count: 16),
        count: 16
    )

    /// Undo/Redo 스택
    var undoStack: [[[StitchColor]]] = []
    var redoStack: [[[StitchColor]]] = []

    /// 현재 그리기 모드 (draw or eraser)
    var isDrawMode: Bool = true

    /// 현재 선택된 스티치 색상
    var selectedStitchColor: StitchColor = .white

    /// 바디 이미지 (픽셀 그리드를 이미지로 변환한 결과)
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0

    /// 체인 길이 (Pixel은 1)
    var chainLength: Int { 1 }

    /// 템플릿 ID
    var templateId: String {
        template?.id ?? "CrossStitch"
    }

    // MARK: - 정보 입력
    var nameText: String = ""
    var maxTextCount: Int = 10
    var memoText: String = ""
    var maxMemoCount: Int = 500
    var selectedTags: [String] = []
    var createdAt: Date = Date()
    var savedKeyringDocumentId: String?
    var packagedPostOfficeId: String?
    var packagedShareLink: String?

    // MARK: - Grid Size 설정
    func setGridSize(_ size: CrossStitchGridSize) {
        gridSize = size.rawValue
        stitchGrid = Array(repeating: Array(repeating: .white, count: gridSize), count: gridSize)
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    // MARK: - 초기화
    init(userManager: UserManager = UserManager.shared) {
        self.userManager = userManager
    }

    // MARK: - Stitch Drawing Methods

    /// 스티치 칠하기
    func paintStitch(row: Int, col: Int) {
        guard row >= 0, row < gridSize, col >= 0, col < gridSize else { return }

        let newColor: StitchColor = isDrawMode ? selectedStitchColor : .white

        // 이미 같은 색이면 무시
        if stitchGrid[row][col] == newColor { return }

        saveToUndoStack()
        stitchGrid[row][col] = newColor
        redoStack.removeAll()
    }

    private func saveToUndoStack() {
        undoStack.append(stitchGrid)
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        redoStack.append(stitchGrid)
        stitchGrid = undoStack.removeLast()
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        undoStack.append(stitchGrid)
        stitchGrid = redoStack.removeLast()
    }

    func clearGrid() {
        saveToUndoStack()
        stitchGrid = Array(repeating: Array(repeating: .white, count: gridSize), count: gridSize)
        redoStack.removeAll()
    }

    // MARK: - 스티치 데이터 초기화
    func resetStitchData() {
        stitchGrid = Array(repeating: Array(repeating: .white, count: gridSize), count: gridSize)
        undoStack.removeAll()
        redoStack.removeAll()
        bodyImage = nil
        isDrawMode = true
        selectedStitchColor = .white
    }

    // MARK: - 완전 초기화
    func resetAll() {
        resetStitchData()
        resetCustomizingData()
        resetInfoData()
    }

    // MARK: - Firebase Template 가져오기
    func fetchTemplate() async {
        isLoadingTemplate = true
        defer { isLoadingTemplate = false }

        do {
            let document = try await Firestore.firestore()
                .collection("Template")
                .document("CrossStitch")
                .getDocument()

            template = try document.data(as: KeyringTemplate.self)
        } catch {
            print("템플릿을 불러오는데 실패했습니다: \(error)")
        }
    }

    // MARK: - Firebase Effects 가져오기
    func fetchEffects() async {
        guard let user = userManager.currentUser else {
            print("유저 정보를 불러올 수 없습니다.")
            return
        }

        do {
            // Sound 전체 가져오기
            let soundsSnapshot = try await Firestore.firestore()
                .collection("Sound")
                .activeItems()

            let allSounds = try soundsSnapshot.documents.compactMap {
                try $0.data(as: Sound.self)
            }

            let ownedSounds = allSounds.filter { sound in
                guard let id = sound.id else { return false }
                return user.soundEffects.contains(id)
            }
            let notOwnedSounds = allSounds.filter { sound in
                guard let id = sound.id else { return false }
                return !user.soundEffects.contains(id)
            }

            availableSounds = ownedSounds + notOwnedSounds

            // Particle 전체 가져오기
            let particlesSnapshot = try await Firestore.firestore()
                .collection("Particle")
                .activeItems()

            let allParticles = try particlesSnapshot.documents.compactMap {
                try $0.data(as: Particle.self)
            }

            let ownedParticles = allParticles.filter { particle in
                guard let id = particle.id else { return false }
                return user.particleEffects.contains(id)
            }
            let notOwnedParticles = allParticles.filter { particle in
                guard let id = particle.id else { return false }
                return !user.particleEffects.contains(id)
            }

            availableParticles = ownedParticles + notOwnedParticles
        } catch {
            print("이펙트 목록을 불러오는데 실패했습니다: \(error)")
        }
    }

    // MARK: - Sorting Helper
    private func getSortPriority(isFree: Bool, isDownloaded: Bool) -> Int {
        if isFree && isDownloaded { return 1 }
        if !isFree && isDownloaded { return 2 }
        if isFree && !isDownloaded { return 3 }
        if !isFree && !isDownloaded { return 4 }
        return 99
    }

    // MARK: - Customizing Modes
    var availableCustomizingModes: [CustomizingMode] {
        [.effect]
    }
}
