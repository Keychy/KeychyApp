//
//  BundleKeyringCellView.swift
//  Keychy
//
//  Created by 길지훈 on 2/6/26.
//

import SwiftUI
import SpriteKit

/// Bundle 전용 키링 셀 뷰 (단순화 버전)
/// - 캐시된 이미지 표시
/// - 캐시 없으면 Scene fallback
/// - 상태 오버레이
struct BundleKeyringCellView: View {
    let keyring: Keyring
    let isSelected: Bool

    @State private var isLoading = true
    @State private var cachedImage: UIImage?
    @State private var scene: KeyringCellScene?
    
    var body: some View {
        ZStack {
            Color.white100
            
            // 콘텐츠
            if let image = cachedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let scene = scene {
                SpriteView(scene: scene)
            }
            
            // 로딩
            if isLoading && cachedImage == nil && scene == nil {
                LoadingAlert(type: .short40, message: nil)
            }
            
            // 상태 오버레이 (포장중/출품중)
            if let info = keyring.status.overlayInfo {
                statusOverlay(info: info)
            } else {
                // 선택 원 (선택 시 체크마크, 미선택 시 빈 원)
                selectionCircle
            }
        }
        .onAppear { loadContent() }
        .onDisappear { cleanupScene() }
    }
    
    // MARK: - 로딩
    private func loadContent() {
        // 1. 캐시 확인
        if let keyringID = keyring.documentId,
           let imageData = KeyringImageCache.shared.load(for: keyringID, type: .thumbnail),
           let image = UIImage(data: imageData) {
            cachedImage = image
            isLoading = false
            return
        }
        
        // 2. 캐시 없으면 Scene 생성
        createScene()
    }
    
    private func createScene() {
        let newScene = KeyringCellScene(
            ringType: RingType.fromID(keyring.selectedRing),
            chainType: ChainType.fromID(keyring.selectedChain),
            bodyImage: keyring.bodyImage,
            templateId: keyring.selectedTemplate,
            isGyroscope: keyring.isGyroscope,
            targetSize: CGSize(width: 175, height: 233),
            zoomScale: 2.0,
            hookOffsetY: keyring.hookOffsetY,
            chainLength: keyring.chainLength,
            shimmerColorId: keyring.shimmerColorId,
            borderColorId: keyring.borderColorId,
            onLoadingComplete: {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        )
        newScene.scaleMode = .aspectFill
        scene = newScene
    }
    
    private func cleanupScene() {
        scene?.removeAllChildren()
        scene?.removeAllActions()
        scene?.physicsWorld.removeAllJoints()
        scene?.view?.presentScene(nil)
        scene = nil
    }
    
    // MARK: - 선택 원
    private var selectionCircle: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if isSelected {
                    Circle()
                        .fill(.main500)
                        .frame(width: 26.14, height: 26.14)
                        .overlay(
                            Image(.checkMarkWhite)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(.white100, lineWidth: 1)
                                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 0)
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 0)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 26.14, height: 26.14)
                        .overlay(
                            Circle()
                                .strokeBorder(.white100, lineWidth: 1)
                                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 0)
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 0)
                }
            }
        }
        .padding(6)
    }

    // MARK: - 상태 오버레이
    private func statusOverlay(info: String) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.black50)
            .overlay {
                VStack {
                    Text(info)
                        .typography(.suit12M)
                        .foregroundColor(keyring.status == .packaged ? .white100 : .main500)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background {
                            if keyring.status == .packaged {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black60)
                                    .frame(height: 23)
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.gradient(.festivalPublished))
                                    .frame(height: 23)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(.main50, lineWidth: 1)
                                    )
                            }
                        }
                    Spacer()
                }
                .padding(6)
            }
    }
}
