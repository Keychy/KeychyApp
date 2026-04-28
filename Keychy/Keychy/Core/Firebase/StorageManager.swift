//
//  StorageManager.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import FirebaseStorage
import Nuke

class StorageManager {

    static let shared = StorageManager()

    private init() {}
    
    func getData(path: String) async throws -> Data {
        guard let url = URL(string: path) else {
            print("잘못된 URL: \(path)")
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return data
    }
    
    // MARK: - 이미지 로드 (Nuke 파이프라인)
    // 메모리 캐시 → DataCache(디스크) → 네트워크 순서로 자동 처리
    func getImage(path: String) async throws -> UIImage {
        guard let url = URL(string: path) else {
            throw URLError(.badURL)
        }
        return try await ImagePipeline.shared.image(for: url)
    }

    /// Nuke 메모리 캐시 + DataCache(디스크)에 이미지가 존재하는지 동기적으로 확인
    func isCached(path: String) -> Bool {
        guard let url = URL(string: path) else { return false }
        return ImagePipeline.shared.cache.containsCachedImage(for: ImageRequest(url: url))
    }

    // MARK: - 업로드

    /// 이미지 업로드 (PNG)
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.pngData() else {
            throw NSError(domain: "StorageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "PNG 변환 실패"])
        }

        let storageRef = Storage.storage().reference().child(path)
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()

        return downloadURL.absoluteString
    }

    /// 오디오 업로드 (M4A)
    func uploadAudio(_ audioData: Data, path: String) async throws -> String {
        let storageRef = Storage.storage().reference().child(path)
        _ = try await storageRef.putDataAsync(audioData)
        let downloadURL = try await storageRef.downloadURL()

        return downloadURL.absoluteString
    }

    /// 범용 데이터 업로드
    func uploadData(_ data: Data, path: String) async throws -> String {
        let storageRef = Storage.storage().reference().child(path)
        _ = try await storageRef.putDataAsync(data)
        let downloadURL = try await storageRef.downloadURL()

        return downloadURL.absoluteString
    }

    // MARK: - 삭제

    /// 특정 파일 삭제
    func deleteFile(path: String) async throws {
        let storageRef = Storage.storage().reference().child(path)
        try await storageRef.delete()
    }

    /// 사용자 폴더 전체 삭제 (Keyrings/BodyImages/{uid}/, Keyrings/CustomSounds/{uid}/)
    func deleteUserFolder(uid: String) async throws {
        let bodyImagesPath = "Keyrings/BodyImages/\(uid)"
        let customSoundsPath = "Keyrings/CustomSounds/\(uid)"

        // 두 폴더 병렬 삭제
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.deleteFolder(path: bodyImagesPath) }
            group.addTask { try await self.deleteFolder(path: customSoundsPath) }
            try await group.waitForAll()
        }
    }

    /// 폴더 삭제 (모든 하위 파일 병렬 삭제)
    private func deleteFolder(path: String) async throws {
        let storageRef = Storage.storage().reference().child(path)

        do {
            let result = try await storageRef.listAll()

            // 파일들 병렬 삭제
            try await withThrowingTaskGroup(of: Void.self) { group in
                for item in result.items {
                    group.addTask {
                        try await item.delete()
                    }
                }
                try await group.waitForAll()
            }

            // 하위 폴더들 병렬 삭제
            try await withThrowingTaskGroup(of: Void.self) { group in
                for prefix in result.prefixes {
                    group.addTask {
                        try await self.deleteFolder(path: prefix.fullPath)
                    }
                }
                try await group.waitForAll()
            }

            print("Storage 폴더 삭제 완료: \(path)")
        } catch {
            if (error as NSError).code == StorageErrorCode.objectNotFound.rawValue {
                print("Storage 폴더 없음 (이미 삭제됨): \(path)")
            } else {
                throw error
            }
        }
    }

}
