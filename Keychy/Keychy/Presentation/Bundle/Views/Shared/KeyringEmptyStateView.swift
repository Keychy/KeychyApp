//
//  KeyringEmptyStateView.swift
//  Keychy
//
//  Created by Claude on 2/6/26.
//

import SwiftUI

struct KeyringEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(.surprisedAlert)

            Text("공방에서 키링을 만들어보세요.\n아직 만들어진 키링이 없어요.")
                .typography(.suit15R)
                .foregroundStyle(.black100)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
