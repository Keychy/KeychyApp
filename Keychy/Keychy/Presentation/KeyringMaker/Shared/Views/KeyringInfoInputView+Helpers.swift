//
//  KeyringInfoInputView+Helpers.swift
//  Keychy
//
//  Helper components for KeyringInfoInputView
//

import SwiftUI

// MARK: - Computed Properties
extension KeyringInfoInputView {
    /// 시트가 펼쳐진 상태인지 확인
    var isSheetExpanded: Bool {
        sheetDetent != .height(76)
    }
    
    /// 씬 스케일 (시트 최대화 시 작게, 최소화 시 크게)
    var sceneScale: CGFloat {
        isSheetExpanded ? 0.6 : 1.0
    }
    
    /// 씬 Y 오프셋 (시트 최대화 시 위로 이동)
    var sceneYOffset: CGFloat {
        isSheetExpanded ? -120 : 0
    }
    
    /// 다음 버튼 활성화 조건
    var isNextButtonEnabled: Bool {
        // 이름이 비어있거나 욕설이 포함되어 있으면 비활성화
        guard !viewModel.nameText.isEmpty && !hasProfanity else {
            return false
        }
        
        // WishHorse26 템플릿일 때는 메모도 필수
        if viewModel.templateId == "WishHorse26" {
            return !viewModel.memoText.isEmpty
        }
        
        return true
    }
}

// MARK: - KeyringScene Section
extension KeyringInfoInputView {
    var keyringScene: some View {
        KeyringSceneView(viewModel: viewModel)
            .frame(maxWidth: .infinity)
            .scaleEffect(sceneScale)
            .offset(y: sceneYOffset)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: sheetDetent)
            .allowsHitTesting(!isSheetExpanded)
    }
}

// MARK: - CustomNavigationBar
extension KeyringInfoInputView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽)
            BackToolbarButton {
                showSheet = false
                viewModel.resetInfoData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.pop()
                }
            }
        } center: {
            // Center (중앙)
            Spacer()
        } trailing: {
            // Trailing (오른쪽)
            Button {
                // 네트워크 체크
                guard NetworkManager.shared.isConnected else {
                    ToastManager.shared.show()
                    return
                }

                // 1. 키보드 닫기 & 시트 내리기
                dismissKeyboard()
                showSheet = false

                // 2. 시트 애니메이션 후 Firebase 저장 시작
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    saveKeyringToFirebase()
                }
            } label: {
                Text("다음")
                    .typography(.suit17B)
                    .foregroundStyle(isNextButtonEnabled ? .main500 : .gray300)
                    .padding(5)
            }
            .buttonStyle(.glassProminent)
            .tint(isNextButtonEnabled ? .white100 : .clear)
            .allowsHitTesting(isNextButtonEnabled && !isSavingToFirebase)
        }
    }
}

// MARK: - KeyboardResponder
@Observable
final class KeyboardResponder {
    private var notificationCenter: NotificationCenter
    private(set) var currentHeight: CGFloat = 0
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
    }

    @objc func keyBoardWillHide(notification: Notification) {
        currentHeight = 0
    }
}
