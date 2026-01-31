//
//  ShareSheet.swift
//  Keychy
//
//  Created by 길지훈 on 1/31/26.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    var onComplete: ((Bool) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = { activityType, completed, items, error in
            if let error = error {
                print("[ShareSheet] 에러: \(error.localizedDescription)")
            }
            print("[ShareSheet] activityType: \(activityType?.rawValue ?? "nil"), completed: \(completed)")
            onComplete?(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
