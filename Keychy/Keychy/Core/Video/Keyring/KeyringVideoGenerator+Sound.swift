//
//  KeyringVideoGenerator+Sound.swift
//  Keychy
//
//  Created by 길지훈 on 1/13/26.
//

import Foundation
import AVFoundation
import CoreMedia
import SpriteKit

// MARK: - Sound Effects

extension KeyringVideoGenerator {

    /// 특정 프레임에서 사운드 이벤트 기록
    /// - 0.5초(30 프레임): 스와이프 임팩트 시 사운드
    func triggerSoundEvents(at frameIndex: Int, scene: KeyringScene) {
        if frameIndex == swipeEventFrame {
            let velocity = CGVector(dx: swipeVelocity, dy: 0)
            scene.applySwipeForceToNearbyChains(
                at: CGPoint(
                    x: scene.size.width / 2,
                    y: scene.size.height / 2
                ),
                velocity: velocity
            )

            if scene.currentSoundId != "none" {
                soundEvents.append(SoundEvent(
                    time: 0.5,
                    soundId: scene.currentSoundId
                ))
            }
        }
    }

    /// 비디오에 사운드 트랙 추가
    /// soundEvents 배열 기반으로 사운드 파일을 비디오에 합성
    func addSoundToVideo(videoURL: URL) async throws -> URL {
        // 사운드 이벤트 없으면 원본 반환
        guard !soundEvents.isEmpty else {
            return videoURL
        }

        let composition = AVMutableComposition()

        // 비디오 트랙 추가
        let videoAsset = AVURLAsset(url: videoURL)
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first else {
            return videoURL
        }

        let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        let videoDuration = try await videoAsset.load(.duration)
        try compositionVideoTrack?.insertTimeRange(
            CMTimeRange(start: .zero, duration: videoDuration),
            of: videoTrack,
            at: .zero
        )

        // 오디오 트랙 추가
        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        // 각 사운드 이벤트를 오디오 트랙에 삽입
        for event in soundEvents {
            guard let soundURL = findSoundURL(soundId: event.soundId) else {
                continue
            }

            let audioAsset = AVURLAsset(url: soundURL)

            do {
                let tracks = try await audioAsset.loadTracks(withMediaType: .audio)

                guard let audioTrack = tracks.first else {
                    continue
                }

                let audioDuration = try await audioAsset.load(.duration)
                let startTime = CMTime(seconds: event.time, preferredTimescale: 600)

                try compositionAudioTrack?.insertTimeRange(
                    CMTimeRange(start: .zero, duration: audioDuration),
                    of: audioTrack,
                    at: startTime
                )
            } catch {
                print("[VideoGenerator] 오디오 트랙 삽입 실패: \(error.localizedDescription)")
            }
        }

        // 최종 비디오 Export
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("keyring_video_with_audio_\(UUID()).mp4")

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw VideoError.saveFailed
        }

        try await exportSession.export(to: outputURL, as: .mp4)

        // 원본 비디오 파일 삭제
        try? FileManager.default.removeItem(at: videoURL)

        return outputURL
    }

    /// 사운드 파일 URL 찾기
    /// 1. Firebase Storage URL인 경우 (커스텀 사운드) 캐시에서 파일명으로 찾기
    /// 2. 일반 사운드 ID인 경우 캐시에서 찾기
    private func findSoundURL(soundId: String) -> URL? {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let soundsDir = cacheDirectory.appendingPathComponent("sounds")

        // 1. Firebase Storage URL (커스텀 사운드)
        if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
            let fileName = soundId.firebaseStorageFileName
            let cachedURL = soundsDir.appendingPathComponent(fileName)

            guard FileManager.default.fileExists(atPath: cachedURL.path) else {
                return nil
            }
            return cachedURL
        }

        // 2. 일반 사운드 ID (Firebase 캐시)
        let cachedURL = soundsDir.appendingPathComponent("\(soundId).mp3")

        guard FileManager.default.fileExists(atPath: cachedURL.path) else {
            return nil
        }
        return cachedURL
    }
}
