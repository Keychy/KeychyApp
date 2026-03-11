//
//  StorageManager.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import FirebaseStorage
import CryptoKit

@Observable
class StorageManager {
    
    static let shared = StorageManager()
    
    private var imageCache: [String: UIImage] = [:]
    private let cacheQueue = DispatchQueue(label: "com.keychy.storageCache", attributes: .concurrent)

    // iOS가 저장공간 부족 시 자동 정리해주는 cachesDirectory 사용
    private var diskCacheDirectory: URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDir.appendingPathComponent("StorageImageCache")
    }

    private init() {}
    
    func getData(path: String) async throws -> Data {
        guard let url = URL(string: path) else {
            print("잘못된 URL: \(path)")
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return data
    }
    
    // MARK: - URL에서 이미지 가져오기
    // 로드 순서: 메모리 캐시 → 디스크 캐시 → 네트워크
    func getImage(path: String) async throws -> UIImage {
        // 1) 메모리 캐시 확인 (즉시)
        if let cachedImage = getCachedImage(for: path) {
            return cachedImage
        }

        // 2) 디스크 캐시 확인 (~5ms)
        if let diskImage = getDiskCachedImage(for: path) {
            setCachedImage(diskImage, for: path)
            return diskImage
        }

        // 3) 네트워크 다운로드 → 메모리 + 디스크 캐시 저장
        let data = try await getData(path: path)

        guard let image = UIImage(data: data) else {
            print("이미지 변환 실패: \(path)")
            throw URLError(.badServerResponse)
        }

        setCachedImage(image, for: path)
        saveToDiskCache(data, for: path)

        return image
    }
    
    func getMultipleImages(paths: [String]) async throws -> [String: UIImage] {
        
        return try await withThrowingTaskGroup(of: (String, UIImage).self) { group in
            var images: [String: UIImage] = [:]
            
            for path in paths {
                group.addTask {
                    let image = try await self.getImage(path: path)
                    return (path, image)
                }
            }
            
            for try await (path, image) in group {
                images[path] = image
            }
            
            return images
        }
    }
    
    // MARK: - 캐시 관리 (수정 예정)
    private func getCachedImage(for path: String) -> UIImage? {
        cacheQueue.sync {
            return imageCache[path]
        }
    }
    
    private func setCachedImage(_ image: UIImage, for path: String) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache[path] = image
        }
    }
    
    // 특정 이미지 캐시 삭제 (메모리 + 디스크)
    func removeCachedImage(for path: String) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeValue(forKey: path)
        }
        removeDiskCachedImage(for: path)
    }

    // 전체 캐시 삭제 (메모리 + 디스크)
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
        }
        clearDiskCache()
    }

    /// 메모리 캐시 또는 디스크 캐시에 해당 path의 이미지가 존재하는지 동기적으로 확인
    func isCached(path: String) -> Bool {
        if getCachedImage(for: path) != nil { return true }
        let fileURL = diskCacheDirectory.appendingPathComponent(diskCacheKey(for: path))
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // MARK: - 디스크 캐시

    /// URL → SHA256 해시 문자열 (파일명으로 안전하게 사용 가능)
    private func diskCacheKey(for path: String) -> String {
        let digest = SHA256.hash(data: Data(path.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// 디스크에서 이미지 읽기
    private func getDiskCachedImage(for path: String) -> UIImage? {
        let fileURL = diskCacheDirectory.appendingPathComponent(diskCacheKey(for: path))
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    /// 원본 Data를 디스크에 저장 (백그라운드에서 실행)
    private func saveToDiskCache(_ data: Data, for path: String) {
        let dir = diskCacheDirectory
        let fileURL = dir.appendingPathComponent(diskCacheKey(for: path))
        DispatchQueue.global(qos: .utility).async {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    /// 개별 디스크 캐시 삭제
    private func removeDiskCachedImage(for path: String) {
        let fileURL = diskCacheDirectory.appendingPathComponent(diskCacheKey(for: path))
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// 전체 디스크 캐시 삭제
    private func clearDiskCache() {
        try? FileManager.default.removeItem(at: diskCacheDirectory)
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
