//
//  BundleSearchBar.swift
//  Keychy
//
//  Created by Claude on 2/6/26.
//

import SwiftUI

struct BundleSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(#colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)))

            TextField("검색", text: $searchText)
                .foregroundStyle(Color(#colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)))
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray400)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(#colorLiteral(red: 0.462745098, green: 0.462745098, blue: 0.5019607843, alpha: 0.12)))
        )
    }
}
