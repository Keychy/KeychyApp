//
//  DataInitializer.swift
//  Keychy
//
//  Firestore에 새 아이템을 추가할 때 사용하는 초기화 도구
//
//  사용법:
//  1. 추가할 아이템 타입의 함수(예: initializeBackgrounds)에 데이터 추가
//  2. 해당 함수 "만" 호출
//  3. Firestore 콘솔에서 업로드 확인
//  4. 테스트 완료 시에만, isActive → true로 변경
//
//  지원 컬렉션:
//  - Background: 번들 배경 (정적 / Lottie)
//  - Carabiner: 카라비너 (plain / hamburger, 정적 / Lottie)
//  - Particle: 파티클 이펙트
//  - Sound: 사운드 이펙트
//  - Template: 키링 템플릿

import FirebaseFirestore

// MARK: - Background

/// 배경 아이템 Firestore 업로드
///
/// 필수 필드:
/// - id: 문서 ID (영문, 공백 없음)
/// - backgroundName: 표시 이름
/// - description: 설명
/// - backgroundImage: 썸네일 이미지 URL (Firebase Storage)
/// - recommendedCombinations: 추천 조합 (빈 문자열 가능)
/// - tags: 태그 배열
/// - price: 가격 (0 = 무료)
///
/// Lottie 배경 추가 필드:
/// - backgroundLottie: Lottie JSON URL (gs:// 경로)
///
/// 사용 예:
/// ```swift
/// await initializeBackgrounds()
/// ```
func initializeBackgrounds() async {
    let backgrounds: [[String: Any]] = [
        // 예시 — 정적 배경
//        [
//            "id": "NewBackground",
//            "backgroundName": "새 배경",
//            "description": "새 배경 설명",
//            "backgroundImage": "https://firebasestorage.googleapis.com/...",
//            "recommendedCombinations": "",
//            "tags": ["배경"],
//            "price": 0,
//            "downloadCount": 0,
//            "useCount": 0,
//            "isActive": false
//        ],

        // 예시 — Lottie 배경
//        [
//            "id": "NewLottieBackground",
//            "backgroundName": "새 Lottie 배경",
//            "description": "새 Lottie 배경 설명",
//            "backgroundImage": "https://firebasestorage.googleapis.com/...",
//            "backgroundLottie": "gs://keychy-f6011.firebasestorage.app/Backgrounds/{아이템ID}/background.json",
//            "recommendedCombinations": "",
//            "tags": ["배경"],
//            "price": 0,
//            "downloadCount": 0,
//            "useCount": 0,
//            "isActive": false
//        ],
    ]

    await uploadItems(backgrounds, collection: "Background")
}

// MARK: - Carabiner

/// 카라비너 아이템 Firestore 업로드
///
/// 필수 필드:
/// - id: 문서 ID
/// - carabinerName: 표시 이름
/// - carabinerImage: 이미지 URL 배열
///   - plain: [썸네일 1개]
///   - hamburger: [썸네일, 뒤면, 앞면] 3개
/// - carabinerType: "plain" 또는 "hamburger"
/// - description: 설명
/// - recommendedCombinations: 추천 조합 (빈 문자열 가능)
/// - maxKeyringCount: 최대 키링 수
/// - tags, price, carabinerX/Y, carabinerWidth, keyringX/YPosition
///
/// Lottie 카라비너 추가 필드:
/// - carabinerLottie: Lottie JSON URL 배열
///
/// 사용 예:
/// ```swift
/// await initializeCarabiners()
/// ```
func initializeCarabiners() async {
    let carabiners: [[String: Any]] = [
        [
            "id": "BaseBall_Bat",
            "carabinerName": "야구 배트",
            "carabinerImage": ["https://firebasestorage.googleapis.com/..."],
            "carabinerType": "plain",
            "description": "야구 배트 모양의 카라비너예요.\n소중한 키링 딱 하나를 걸어보세요.",
            "recommendedCombinations": "",
            "maxKeyringCount": 1,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 56.54,
            "carabinerY": 156,
            "carabinerWidth": 304.28,
            "keyringXPosition": [207.2],
            "keyringYPosition": [187],
            "isActive": false
        ],
        [
            "id": "BaseBall_Helmet_Red",
            "carabinerName": "레드 헬멧",
            "carabinerImage": ["https://firebasestorage.googleapis.com/..."],
            "carabinerType": "plain",
            "description": "헬멧 카라비너예요.\n실점 없이 이닝을 마무리 하길 기원해봐요.",
            "recommendedCombinations": "",
            "maxKeyringCount": 2,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 72.2,
            "carabinerY": 141,
            "carabinerWidth": 229.67724609375,
            "keyringXPosition": [142.15, 254.09],
            "keyringYPosition": [296, 306],
            "isActive": false
        ],
        [
            "id": "BaseBall_Helmet_Blue",
            "carabinerName": "블루 헬멧",
            "carabinerImage": ["https://firebasestorage.googleapis.com/..."],
            "carabinerType": "plain",
            "description": "헬멧 카라비너예요.\n실점 없이 이닝을 마무리 하길 기원해봐요.",
            "recommendedCombinations": "",
            "maxKeyringCount": 2,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 72.2,
            "carabinerY": 141,
            "carabinerWidth": 229.67724609375,
            "keyringXPosition": [142.15, 254.09],
            "keyringYPosition": [296, 306],
            "isActive": false
        ],
        [
            "id": "BaseBall_Purple",
            "carabinerName": "퍼플 헬멧",
            "carabinerImage": ["https://firebasestorage.googleapis.com/..."],
            "carabinerType": "plain",
            "description": "포수 마스크가 함께 있는 헬멧 카라비너예요.\n실점 없이 이닝을 마무리 하길 기원해봐요.",
            "recommendedCombinations": "",
            "maxKeyringCount": 3,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 77.16,
            "carabinerY": 111.77,
            "carabinerWidth": 240.308349609375,
            "keyringXPosition": [88.46, 179.21, 288.02],
            "keyringYPosition": [259, 308.33, 244.06],
            "isActive": false
        ],
        [
            "id": "BaseBall_Ball",
            "carabinerName": "야구공",
            "carabinerImage": ["https://firebasestorage.googleapis.com/..."],
            "carabinerType": "plain",
            "description": "야구공 모양의 카라비너예요⚾️\n소중한 키링 딱 하나를 걸어보세요.",
            "recommendedCombinations": "",
            "maxKeyringCount": 1,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 104.96,
            "carabinerY": 124,
            "carabinerWidth": 197.30393981933594,
            "keyringXPosition": [202.53],
            "keyringYPosition": [297.81],
            "isActive": false
        ],
        [
            "id": "BaseBall_Cap_Pink",
            "carabinerName": "핑크 키치 볼캡",
            "carabinerImage": ["https://firebasestorage.googleapis.com/..."],
            "carabinerType": "plain",
            "description": "볼캡 모양의 카라비너예요.",
            "recommendedCombinations": "",
            "maxKeyringCount": 2,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 66.92,
            "carabinerY": 134.06,
            "carabinerWidth": 240.59140014648438,
            "keyringXPosition": [112.51, 288.03],
            "keyringYPosition": [230.88, 262.28],
            "isActive": false
        ],
        [
            "id": "BaseBall_Cap_Purple",
            "carabinerName": "퍼플 키치 볼캡",
            "carabinerImage": ["https://firebasestorage.googleapis.com/..."],
            "carabinerType": "plain",
            "description": "볼캡 모양의 카라비너예요.",
            "recommendedCombinations": "",
            "maxKeyringCount": 3,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 70.56,
            "carabinerY": 120.53,
            "carabinerWidth": 314.4443359375,
            "keyringXPosition": [78.91, 199.91, 297.28],
            "keyringYPosition": [234, 279.68, 231],
            "isActive": false
        ],
    ]

    await uploadItems(carabiners, collection: "Carabiner")
}

// MARK: - Particle

/// 파티클 이펙트 Firestore 업로드
///
/// 필수 필드:
/// - id, particleName, description
/// - particleData: Lottie JSON URL
/// - thumbnail: 썸네일 URL
/// - tags, price
func initializeParticles() async {
    let particles: [[String: Any]] = [
        // 예시
//        [
//            "id": "NewParticle",
//            "particleName": "새 파티클",
//            "description": "새 파티클 설명",
//            "particleData": "https://firebasestorage.googleapis.com/...",
//            "thumbnail": "https://firebasestorage.googleapis.com/...",
//            "tags": ["파티클"],
//            "price": 0,
//            "downloadCount": 0,
//            "useCount": 0,
//            "isActive": false
//        ],
    ]

    await uploadItems(particles, collection: "Particle")
}

// MARK: - Sound

/// 사운드 이펙트 Firestore 업로드
///
/// 필수 필드:
/// - id, soundName, description
/// - soundData: 사운드 파일 URL
/// - thumbnail: 썸네일 URL
/// - tags, price
func initializeSounds() async {
    let sounds: [[String: Any]] = [
        // 예시
//        [
//            "id": "NewSound",
//            "soundName": "새 사운드",
//            "description": "새 사운드 설명",
//            "soundData": "https://firebasestorage.googleapis.com/...",
//            "thumbnail": "https://firebasestorage.googleapis.com/...",
//            "tags": ["사운드"],
//            "price": 0,
//            "downloadCount": 0,
//            "useCount": 0,
//            "isActive": false
//        ],
    ]

    await uploadItems(sounds, collection: "Sound")
}

// MARK: - ShimmerEffects (렌티큘러 시머)

/// 렌티큘러 시머(광택) 프리셋 가격 Firestore 업로드
///
/// 경로: `Template/Lenticular/ShimmerEffects/{id}`
///
/// 필수 필드:
/// - id: 프리셋 rawValue (예: "hologram", "liquid", "matrix")
/// - price: 가격 (0 = 무료)
///
/// silver는 하드코딩 무료라 컬렉션에 넣지 않음.
func initializeShimmerEffects() async {
    let items: [[String: Any]] = [
        ["id": "hologram", "price": 1000],
        ["id": "liquid",   "price": 500],
        ["id": "matrix",   "price": 500],
    ]
    await uploadItems(items, collection: "ShimmerEffects", parentPath: "Template/Lenticular")
}

// MARK: - BorderEffects (렌티큘러 테두리)

/// 렌티큘러 테두리 프리셋 가격 Firestore 업로드
///
/// 경로: `Template/Lenticular/BorderEffects/{id}`
///
/// 필수 필드:
/// - id: 프리셋 rawValue (예: "hologram", "pulse", "cosmos")
/// - price: 가격 (0 = 무료)
///
/// silver는 하드코딩 무료라 컬렉션에 넣지 않음.
func initializeBorderEffects() async {
    let items: [[String: Any]] = [
        ["id": "hologram", "price": 500],
        ["id": "pulse",    "price": 500],
        ["id": "cosmos",   "price": 500],
    ]
    await uploadItems(items, collection: "BorderEffects", parentPath: "Template/Lenticular")
}

// MARK: - Template

/// 템플릿 Firestore 업로드
///
/// 필수 필드:
/// - id, templateName, description
/// - interactions: 지원 인터랙션 배열
/// - thumbnailURL, previewURL, guidingImageURL, guidingText
/// - tags, price
func initializeTemplates() async {
    let templates: [[String: Any]] = [
        // 예시
//        [
//            "id": "NewTemplate",
//            "templateName": "새 템플릿",
//            "description": "새 템플릿 설명",
//            "interactions": ["tap", "swipe"],
//            "thumbnailURL": "https://firebasestorage.googleapis.com/...",
//            "previewURL": "https://firebasestorage.googleapis.com/...",
//            "guidingImageURL": "",
//            "guidingText": "가이드 텍스트",
//            "tags": ["태그"],
//            "price": 0,
//            "downloadCount": 0,
//            "useCount": 0,
//            "isActive": false
//        ],
    ]

    await uploadItems(templates, collection: "Template")
}

// MARK: - 공통 업로드 로직

/// 아이템 배열을 Firestore에 업로드
/// - 문서가 없으면 createdAt 자동 추가
/// - merge: true로 기존 필드 보존
///
/// - Parameters:
///   - items: 업로드할 아이템 배열 (각 dict에 "id" 키 필수)
///   - collection: 대상 컬렉션 이름
///   - parentPath: 서브컬렉션으로 넣을 때 부모 경로 (예: "Template/Lenticular").
///                 nil이면 루트 컬렉션에 업로드.
private func uploadItems(
    _ items: [[String: Any]],
    collection: String,
    parentPath: String? = nil
) async {
    guard !items.isEmpty else {
        print("[\(collection)] 업로드할 아이템이 없습니다.")
        return
    }

    let db = Firestore.firestore()

    // parentPath가 있으면 서브컬렉션 참조, 없으면 루트 컬렉션 참조
    let targetCollection: CollectionReference = {
        guard let parentPath, !parentPath.isEmpty else {
            return db.collection(collection)
        }
        return db.document(parentPath).collection(collection)
    }()

    // 로그 prefix (서브컬렉션이면 전체 경로 표시)
    let logPrefix = parentPath.map { "\($0)/\(collection)" } ?? collection

    for item in items {
        guard let id = item["id"] as? String else { continue }

        var data = item
        data.removeValue(forKey: "id")

        do {
            let doc = try await targetCollection.document(id).getDocument()

            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }

            try await targetCollection.document(id).setData(data, merge: true)
            print("[\(logPrefix)] \(id) 업로드 완료")
        } catch {
            print("[\(logPrefix)] \(id) 오류: \(error)")
        }
    }
}
