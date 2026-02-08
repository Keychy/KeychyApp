//
//  BundleViewModel+Sort.swift
//  Keychy
//
//  Created by Jini on 2/9/26.
//

import SwiftUI

extension BundleViewModel {
    // MARK: - 정렬 방식
    
    /// 정렬 기준 변경 및 즉시 적용
    func updateSortOrder(_ newSort: String) {
        selectedSort = newSort
    }
    
    /// 뭉치 배열을 정렬 (메인 뭉치는 항상 최상단 유지)
    func sortBundles(_ bundles: [KeyringBundle]) -> [KeyringBundle] {
        // 메인 뭉치와 일반 뭉치 분리
        let mainBundles = bundles.filter { $0.isMain }
        let normalBundles = bundles.filter { !$0.isMain }
        
        // 일반 뭉치를 선택된 정렬 기준으로 정렬
        let sortedNormalBundles: [KeyringBundle]
        
        switch selectedSort {
        case "최신순":
            sortedNormalBundles = normalBundles.sorted { $0.createdAt > $1.createdAt }
        case "오래된순":
            sortedNormalBundles = normalBundles.sorted { $0.createdAt < $1.createdAt }
        case "이름순":
            sortedNormalBundles = normalBundles.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        default:
            sortedNormalBundles = normalBundles.sorted { $0.createdAt > $1.createdAt }
        }
        
        // 메인 뭉치(최신순 정렬) + 정렬된 일반 뭉치
        return mainBundles.sorted { $0.createdAt > $1.createdAt } + sortedNormalBundles
    }
}
