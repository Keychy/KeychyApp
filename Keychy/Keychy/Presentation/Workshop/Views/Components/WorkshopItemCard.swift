//
//  WorkshopItemCard.swift
//  Keychy
//
//  Created by 길지훈 on 1/22/26.
//

import SwiftUI
import NukeUI
import Lottie

// MARK: - Item Card

/// 모든 워크샵 아이템을 표시하는 통합 그리드 아이템 카드
struct WorkshopItemCard<Item: WorkshopItem>: View {
    let item: Item
    var isOwned: Bool = false
    var router: NavigationRouter<WorkshopRoute>? = nil
    var viewModel: WorkshopViewModel? = nil

    @State private var isParticleReady = false
    @State private var effectManager = EffectManager.shared
    @Environment(UserManager.self) private var userManager

    var body: some View {
        Button {
            handleTap()
        } label: {
            VStack(spacing: 8) {
                // 썸네일 이미지
                thumbnailImage

                // 아이템 이름
                Text(item.name)
                    .typography(.suit14SB18)
            }
        }
        .buttonStyle(.plain)
    }

    /// 썸네일 이미지 + 가격 오버레이
    private var thumbnailImage: some View {
        ZStack(alignment: .top) {
            // Particle일 경우 Lottie 애니메이션, Sound는 이미지
            if let particle = item as? Particle {
                if let particleId = item.id {
                    if isParticleReady {
                        LottieView(name: particleId, loopMode: .loop, speed: 1.0)
                            .frame(width: twoGridCellWidth, height: itemHeight)
                            .clipped()
                    } else {
                        LoadingAlert(type: .short40, message: nil)
                            .task {
                                await ensureParticleReady(particle)
                            }
                    }
                }
            } else if let background = item as? Background, background.isLottie, let bgId = background.id {
                // Lottie 배경
                LottieItemView(assetId: bgId, directory: "lottie_backgrounds")
                    .frame(width: twoGridCellWidth, height: itemHeight)
                    .clipped()
            } else if let carabiner = item as? Carabiner, carabiner.isLottie, let cbId = carabiner.id {
                // Lottie 카라비너
                LottieItemView(assetId: cbId, directory: "lottie_carabiners_back", contentMode: .scaleAspectFit)
                    .padding(.horizontal, 5)
                    .frame(width: twoGridCellWidth, height: itemHeight)
                    .clipped()
            } else {
                // Sound, Background, Carabiner, 키링 등은 기존처럼 이미지로 처리 (GIF 지원)
                SimpleAnimatedImage(url: item.thumbnailURL)
                    .aspectRatio(contentMode: item is Carabiner || item is KeyringTemplate ? .fit : .fill)
                    .padding(.horizontal, item is Carabiner ? 5 : 0)
                    .padding(.vertical, item is KeyringTemplate ? 10 : 0)
                    .clipped()
                    .frame(width: twoGridCellWidth, height: itemHeight)
            }

            // 가격 오버레이
            WorkshopPriceOverlay(
                isFree: item.isFree,
                price: item.workshopPrice,
                isOwned: isOwned,
                item: item,
                effectManager: effectManager,
                userManager: userManager
            )
        }
        .frame(width: twoGridCellWidth, height: itemHeight)
        .background(Color.gray50)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray50, lineWidth: 2)
        )
    }

    /// 아이템 타입에 따른 높이 계산
    private var itemHeight: CGFloat {
        if item is KeyringTemplate || item is Background {
            return twoGridCellHeight
        } else {
            return twoSquareGridCellSize
        }
    }

    /// 탭 핸들러 (키링은 바로 만들기, 나머지는 WorkshopItemDetailView로 이동)
    private func handleTap() {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }

        guard let router = router else { return }

        // 키링 템플릿일 경우 해당 Preview로 이동
        if let template = item as? KeyringTemplate,
           let templateId = template.id,
           let route = WorkshopRoute.from(string: templateId) {
            router.push(route)
            return
        }

        // 나머지 아이템들은 WorkshopItemDetailView로 이동
        if let background = item as? Background {
            router.push(.workshopPreview(item: AnyHashable(background)))
        } else if let carabiner = item as? Carabiner {
            router.push(.workshopPreview(item: AnyHashable(carabiner)))
        } else if let particle = item as? Particle {
            router.push(.workshopPreview(item: AnyHashable(particle)))
        } else if let sound = item as? Sound {
            router.push(.workshopPreview(item: AnyHashable(sound)))
        }
    }

    private func ensureParticleReady(_ particle: Particle) async {
        guard let particleId = particle.id else { return }

        // 이미 캐시 또는 Bundle에 있으면 바로 준비 완료
        if effectManager.isInCache(particleId: particleId) || effectManager.isInBundle(particleId: particleId) {
            isParticleReady = true
            return
        }

        // 다운로드 필요
        await effectManager.downloadParticle(particle, userManager: userManager)

        isParticleReady = true
    }
}

// MARK: - Price Overlay

/// 공통 가격 오버레이 (유료 표시)
struct WorkshopPriceOverlay<Item: WorkshopItem>: View {
    let isFree: Bool
    let price: Int
    let isOwned: Bool
    let item: Item
    let effectManager: EffectManager
    let userManager: UserManager

    var body: some View {
        ZStack {
            // 유료: 오른쪽 상단에 가격 또는 보유 표시
            VStack {
                HStack {
                    Spacer()
                    if isOwned {
                        // 보유
                        Text("보유")
                            .typography(.suit13M)
                            .foregroundStyle(.white100)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.black60)
                            )
                    } else {
                        // 미보유: 가격 표시
                        Text("\(price)")
                            .typography(.nanum16EB)
                            .foregroundStyle(.white100)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.mainOpacity80)
                            )
                    }
                }
                .padding(10)
                Spacer()
            }
            .opacity(isFree ? 0 : 1)
        }

        // 사운드인 경우에만 재생 버튼 표시
        if item is Sound {
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    SoundPlayButton(
                        item: item,
                        effectManager: effectManager,
                        userManager: userManager
                    )
                    .padding(8)
                }
            }
        }
    }
}

// MARK: - Sound Play Button

struct SoundPlayButton<Item: WorkshopItem>: View {
    let item: Item
    let effectManager: EffectManager
    let userManager: UserManager

    private var itemId: String {
        item.id ?? ""
    }

    private var isDownloading: Bool {
        effectManager.downloadingItemIds.contains(itemId)
    }

    private var progress: Double {
        effectManager.downloadProgress[itemId] ?? 0.0
    }

    var body: some View {
        Button {
            Task {
                if let sound = item as? Sound {
                    await effectManager.playSound(sound, userManager: userManager)
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray50)
                    .frame(width: 38, height: 38)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .inset(by: 0.5)
                            .stroke(.white100, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)

                if isDownloading {
                    // 다운로드 중이면 프로그레스 표시
                    DownloadProgressRing(progress: progress)
                        .frame(width: 25, height: 25)
                } else {
                    Image(.polygon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .offset(x: 1)
                }
            }
        }
        .disabled(isDownloading)
    }
}

// MARK: - Download Progress Ring

/// 원형 프로그레스 뷰
struct DownloadProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray300, lineWidth: 2)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white100, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
    }
}
