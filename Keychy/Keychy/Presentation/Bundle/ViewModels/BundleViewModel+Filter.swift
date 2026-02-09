//
//  BundleViewModel+Filter.swift
//  Keychy
//
//  Created by Jini on 2/9/26.
//

import SwiftUI

extension BundleViewModel {
    // MARK: - 검색 키워드 필터링
    /// 검색어로 뭉치 필터링 (이름 기준)
    func getFilteredBundles(searchText: String = "") -> [KeyringBundle] {
        var result = bundles
        
        // 검색 필터
        if !searchText.isEmpty {
            result = result.filter { bundle in
                bundle.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 정렬 적용
        return sortBundles(result)
    }
}
