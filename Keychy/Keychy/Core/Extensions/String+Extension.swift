//
//  String+Extension.swift
//  Keychy
//
//  Created by Jini on 11/19/25.
//

import SwiftUI

/// 줄바꿈 시 단어 단위로 자르기 위함
/// 사용법 : Text(memo.byCharWrapping)
extension String {
    var byCharWrapping: Self {
        map(String.init).joined(separator: "\u{200B}")
    }

    /// Firebase Storage URL에서 파일명 추출
    /// URL 형식: https://firebasestorage.googleapis.com/v0/b/.../o/path%2Fto%2Ffile.m4a?alt=media&token=xxx
    var firebaseStorageFileName: String {
        // /o/ 이후의 경로 추출
        guard let oRange = range(of: "/o/") else {
            return URL(string: self)?.lastPathComponent ?? "custom_sound.m4a"
        }

        // /o/ 이후부터 ? 이전까지 추출
        var encodedPath = String(self[oRange.upperBound...])
        if let queryIndex = encodedPath.firstIndex(of: "?") {
            encodedPath = String(encodedPath[..<queryIndex])
        }

        // URL 디코딩
        let decodedPath = encodedPath.removingPercentEncoding ?? encodedPath

        // 마지막 경로 컴포넌트 (파일명) 추출
        let components = decodedPath.components(separatedBy: "/")
        return components.last ?? "custom_sound.m4a"
    }
}
