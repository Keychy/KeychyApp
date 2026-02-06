//
//  BundleViewModel+Views.swift
//  Keychy
//
//  Created by 길지훈 on 2/5/26.
//

// MARK: - BundleViewModel+Views
//
// SwiftUI ViewBuilder 메서드
// - bundleCaptureSceneView: 캡쳐 미리보기
// - backCarabinerImage: 뒷 카라비너 이미지
// - frontCarabinerImage: 앞 카라비너 이미지
// - backgroundImage: 배경 이미지

import SwiftUI
import NukeUI

extension BundleViewModel {

    // MARK: - 뭉치 캡쳐 미리보기

    /// BundleNameInputView, BundleNameEditView에서 사용하는 미리보기 씬
    @ViewBuilder
    func bundleCaptureSceneView() -> some View {
        let widthSize = screenWidth - 176
        let heightSize = widthSize * 7/5

        Group {
            if let imageData = bundleCapturedImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .offset(y: 30)
                    .clipped()
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("이미지를 불러오는 중...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: widthSize, height: heightSize)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .clipped()
    }

    // MARK: - 카라비너 이미지

    /// 뒷 카라비너 이미지 (또는 단일 카라비너 이미지)
    func backCarabinerImage(carabiner: Carabiner) -> some View {
        LazyImage(url: URL(string: carabiner.backImageURL)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if state.isLoading {
                ProgressView()
            } else {
                Color.clear
            }
        }
    }

    /// 앞 카라비너 이미지 (햄버거 타입만)
    func frontCarabinerImage(carabiner: Carabiner) -> some View {
        Group {
            if let frontURL = carabiner.frontImageURL {
                LazyImage(url: URL(string: frontURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.isLoading {
                        ProgressView()
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
    }

    // MARK: - 배경 이미지

    /// 배경 이미지 뷰
    var backgroundImage: some View {
        Group {
            if let bundle = selectedBundle,
               let bg = resolveBackground(from: bundle.selectedBackground) {
                LazyImage(url: URL(string: bg.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if state.isLoading {
                        Color.clear
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
    }
}
