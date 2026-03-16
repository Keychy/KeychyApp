//
//  BuildEnvironment.swift
//  Keychy
//
//  Created by 길지훈 on 2026-03-13.
//

import StoreKit
import FirebaseFirestore

/// 빌드 환경 판별 유틸리티
/// - Debug / TestFlight: isTestEnvironment == true → isActive 무시하고 전체 아이템 표시
/// - App Store (프로덕션): isTestEnvironment == false → isActive == true 아이템만 표시
///
/// AppTransaction.environment 값:
/// - .xcode → Simulator / 디바이스 Debug
/// - .sandbox → TestFlight
/// - .production → App Store
enum BuildEnvironment {
    private(set) static var isTestEnvironment: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    /// 앱 시작 시 호출. Release 빌드에서 TestFlight 여부를 확인하여 캐싱.
    static func configure() async {
        #if !DEBUG
        guard let result = try? await AppTransaction.shared,
              case .verified(let transaction) = result else { return }
        isTestEnvironment = transaction.environment != .production
        #endif

        print("[BuildEnvironment] isTestEnvironment: \(isTestEnvironment)")
    }
}

// MARK: - Firestore isActive 필터 헬퍼
extension CollectionReference {
    /// 테스트 환경(Debug/TestFlight)에서는 전체 문서, 프로덕션에서는 isActive == true만 반환
    func activeItems() async throws -> QuerySnapshot {
        if BuildEnvironment.isTestEnvironment {
            return try await getDocuments()
        } else {
            return try await whereField("isActive", isEqualTo: true).getDocuments()
        }
    }
}
