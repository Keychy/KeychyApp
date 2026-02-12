//
//  DataInitializer.swift
//  Keychy
//
//  Firestore에 새 아이템을 추가할 때 사용하는 초기화 도구
//  각 함수의 배열에 데이터를 추가하고 initializeData()를 호출하면 Firestore에 업로드됩니다.
//
//  <길지훈의 따끔한 경고!>
//  isActive는 기본적으로 false로 설정되어 있습니다.
//  배포 전에 Firestore에서 isActive를 true로 변경하세요.
//
//  지원 컬렉션:
//  - Template: 키링 템플릿
//  - Background: 번들 배경
//  - Carabiner: 카라비너
//  - Sound: 사운드 이펙트
//  - Particle: 파티클 이펙트

import FirebaseFirestore

/// 앱 실행 시 한 번만 호출하세요
/// - 원하는 함수를 수정하고, 아래 함수를 호출하세요.
func initializeDatas() async {
    await initializeTemplates()
    await initializeSpeechBubbleTemplate()
    await initializeBackgrounds()
    await initializeCarabiners()
    await initializeParticles()
    await initializeSounds()
}

// MARK: - Background Initialization
func initializeBackgrounds() async {
    let backgrounds: [[String: Any]] = [
        // MARK: 정적 배경 1
        [
            "id": "CheckHeart",
            "backgroundName": "체크 하트",
            "description": "체크 패턴 위에 하트가 그려진 배경이에요.",
            "backgroundImage": "https://placeholder.com/bg.png",
            "tags": ["배경"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
        ],
        // MARK: 정적 배경 2
        [
            "id": "PinkRibbon",
            "backgroundName": "핑크 리본",
            "description": "핑크색 리본이 그려진 배경이에요.",
            "backgroundImage": "https://placeholder.com/bg.png",
            "tags": ["배경"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
        ],
        // MARK: Lottie 배경 1
        [
            "id": "StarlightSky",
            "backgroundName": "별빛 하늘",
            "description": "별빛이 반짝이며 움직이는 하늘 배경이에요.",
            "backgroundImage": "https://placeholder.com/bg.png",
            "backgroundLottie": "gs://keychy-f6011.firebasestorage.app/Backgrounds/REPLACE_ME/background.json",
            "tags": ["배경"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
        ],
        // MARK: Lottie 배경 2
        [
            "id": "AuroraSpace",
            "backgroundName": "오로라 우주",
            "description": "빛이 일렁이는 움직이는 우주 배경이에요.",
            "backgroundImage": "https://placeholder.com/bg.png",
            "backgroundLottie": "gs://keychy-f6011.firebasestorage.app/Backgrounds/REPLACE_ME/background.json",
            "tags": ["배경"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
        ],
        // MARK: Lottie 배경 3
        [
            "id": "CloudBalloonSky",
            "backgroundName": "구름 풍선 하늘",
            "description": "구름 위로 풍선이 떠오르는 움직이는 배경이에요.",
            "backgroundImage": "https://placeholder.com/bg.png",
            "backgroundLottie": "gs://keychy-f6011.firebasestorage.app/Backgrounds/REPLACE_ME/background.json",
            "tags": ["배경"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
        ]
    ]
    
    let db = Firestore.firestore()
    
    for background in backgrounds {
        guard let id = background["id"] as? String else { continue }
        
        var data = background
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Background").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Background").document(id).setData(data, merge: true)
        } catch {
            print("Background \(id) 오류: \(error)")
        }
    }
}

// MARK: - Carabiner Initialization
func initializeCarabiners() async {
    let carabiners: [[String: Any]] = [
        // MARK: Lottie 카라비너 1 (plain)
        [
            "id": "CarouselOrgel",
            "carabinerName": "회전목마 오르골",
            "carabinerImage": ["https://placeholder.com/cb.png"],
            "carabinerLottie": ["gs://keychy-f6011.firebasestorage.app/Carabiners/REPLACE_ME/Carabiner0.json"],
            "carabinerType": "plain",
            "description": "은은한 빛과 함께 오르골 사운드가 담긴 회전목마 카라비너예요.",
            "maxKeyringCount": 3,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 0.0,
            "carabinerY": 0.0,
            "carabinerWidth": 100.0,
            "keyringXPosition": [0.5, 0.3, 0.7],
            "keyringYPosition": [0.3, 0.4, 0.4],
            "isActive": false
        ],
        // MARK: Lottie 카라비너 2 (plain)
        [
            "id": "UfoCat",
            "carabinerName": "UFO 냥",
            "carabinerImage": ["https://placeholder.com/cb.png"],
            "carabinerLottie": ["gs://keychy-f6011.firebasestorage.app/Carabiners/REPLACE_ME/Carabiner0.json"],
            "carabinerType": "plain",
            "description": "고양이 외계인이 UFO에 탑승한 카라비너예요.\n귀여운 움직임도 함께^. .^₎⟆",
            "maxKeyringCount": 3,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 0.0,
            "carabinerY": 0.0,
            "carabinerWidth": 100.0,
            "keyringXPosition": [0.5, 0.3, 0.7],
            "keyringYPosition": [0.3, 0.4, 0.4],
            "isActive": false
        ],
        // MARK: Lottie 카라비너 3 (plain)
        [
            "id": "HeartPlanet",
            "carabinerName": "하트 행성",
            "carabinerImage": ["https://placeholder.com/cb.png"],
            "carabinerLottie": ["gs://keychy-f6011.firebasestorage.app/Carabiners/REPLACE_ME/Carabiner0.json"],
            "carabinerType": "plain",
            "description": "행성 주변을 하트 위성이 공전하고 있는 카라비너예요.",
            "maxKeyringCount": 3,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 0.0,
            "carabinerY": 0.0,
            "carabinerWidth": 100.0,
            "keyringXPosition": [0.5, 0.3, 0.7],
            "keyringYPosition": [0.3, 0.4, 0.4],
            "isActive": false
        ],
        // MARK: 정적 카라비너 1 (hamburger)
        [
            "id": "HeartPepero",
            "carabinerName": "하트 빼빼로",
            "carabinerImage": ["https://placeholder.com/cb_thumb.png", "https://placeholder.com/cb_back.png", "https://placeholder.com/cb_front.png"],
            "carabinerType": "hamburger",
            "description": "하트모양 빼빼로 카라비너예요.\n빼빼로 위에 있는 별에 키링을 걸 수 있어요.",
            "maxKeyringCount": 3,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 0.0,
            "carabinerY": 0.0,
            "carabinerWidth": 100.0,
            "keyringXPosition": [0.5, 0.3, 0.7],
            "keyringYPosition": [0.3, 0.4, 0.4],
            "isActive": false
        ],
        // MARK: 정적 카라비너 2 (plain)
        [
            "id": "MeltingWhiteChoco",
            "carabinerName": "멜팅 화이트 초코",
            "carabinerImage": ["https://placeholder.com/cb.png"],
            "carabinerType": "plain",
            "description": "초콜릿이 녹아 달콤하게 흘러내리며 스프링클이 톡톡 뿌려진 카라비너예요.",
            "maxKeyringCount": 3,
            "tags": ["카라비너"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "carabinerX": 0.0,
            "carabinerY": 0.0,
            "carabinerWidth": 100.0,
            "keyringXPosition": [0.5, 0.3, 0.7],
            "keyringYPosition": [0.3, 0.4, 0.4],
            "isActive": false
        ]
    ]
    
    let db = Firestore.firestore()
    
    for carabiner in carabiners {
        guard let id = carabiner["id"] as? String else { continue }
        
        var data = carabiner
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Carabiner").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Carabiner").document(id).setData(data, merge: true)
        } catch {
            print("Carabiner \(id) 오류: \(error)")
        }
    }
}

// MARK: - Particle Initialization
func initializeParticles() async {
    let particles: [[String: Any]] = [
        [
            "id": "ExampleParticle",
            "particleName": "예시 파티클",
            "description": "새로운 파티클 설명을 입력하세요",
            "particleData": "https://firebasestorage.googleapis.com/...",
            "thumbnail": "https://firebasestorage.googleapis.com/...",
            "tags": ["태그1", "태그2"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
        ]
    ]
    
    let db = Firestore.firestore()
    
    for particle in particles {
        guard let id = particle["id"] as? String else { continue }
        
        var data = particle
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Particle").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Particle").document(id).setData(data, merge: true)
        } catch {
            print("Particle \(id) 오류: \(error)")
        }
    }
}

// MARK: - Sound Initialization
func initializeSounds() async {
    let sounds: [[String: Any]] = [
        [
            "id": "ExampleSound",
            "soundName": "예시 사운드",
            "description": "새로운 사운드 설명을 입력하세요",
            "soundData": "https://firebasestorage.googleapis.com/...",
            "thumbnail": "https://firebasestorage.googleapis.com/...",
            "tags": ["태그1", "태그2"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
        ]
    ]
    
    let db = Firestore.firestore()
    
    for sound in sounds {
        guard let id = sound["id"] as? String else { continue }
        
        var data = sound
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Sound").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Sound").document(id).setData(data, merge: true)
        } catch {
            print("Sound \(id) 오류: \(error)")
        }
    }
}

// MARK: - Template Initialization
func initializeTemplates() async {
    print("안녕하세용~^^")

    let templates: [[String: Any]] = [
        [
            "id": "PixelKeyring",
            "templateName": "픽셀 키링",
            "description": "16x16 픽셀 아트로 나만의 키링을 만들어보세요",
            "interactions": ["tap", "swipe"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/...",
            "previewURL": "https://firebasestorage.googleapis.com/...",
            "guidingImageURL": "",
            "guidingText": "픽셀을 찍어서 나만의 키링을 만들어보세요!",
            "tags": ["픽셀", "그리기", "도트"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
        ]
    ]

    let db = Firestore.firestore()

    for template in templates {
        guard let id = template["id"] as? String else { continue }

        var data = template
        data.removeValue(forKey: "id")

        do {
            let doc = try await db.collection("Template").document(id).getDocument()

            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }

            try await db.collection("Template").document(id).setData(data, merge: true)
        } catch {
            print("Template \(id) 오류: \(error)")
        }
    }
}

// MARK: - SpeechBubble Template Initialization
func initializeSpeechBubbleTemplate() async {
    let db = Firestore.firestore()

    // 메인 템플릿 문서
    let templateData: [String: Any] = [
        "templateName": "말풍선 키링",
        "description": "말풍선 모양의 키링을 만들어보세요",
        "interactions": ["tap", "swipe"],
        "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FArcrlyricPreview.gif?alt=media&token=a1c62e35-e47a-4b0c-9252-6a9b5eda9233",
        "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FArcrylicWhite.gif?alt=media&token=133b13cf-8db9-4e83-af1c-44e5430ca2fb",
        "guidingImageURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicGudingImage..png?alt=media&token=d79a355d-1b85-4d93-b126-cc09828d12da",
        "guidingText": "말풍선에 텍스트를 입력해주세요.",
        "tags": ["텍스트"],
        "price": 0,
        "downloadCount": 0,
        "useCount": 0,
        "hookOffsetY": 0.04,
        "chainLength": 5,
        "isActive": false
    ]

    do {
        let doc = try await db.collection("Template").document("SpeechBubble").getDocument()

        var data = templateData
        if !doc.exists {
            data["createdAt"] = Timestamp(date: Date())
        }

        try await db.collection("Template").document("SpeechBubble").setData(data, merge: true)
        print("SpeechBubble 템플릿 생성 완료")

    } catch {
        print("SpeechBubble 템플릿 생성 오류: \(error)")
        return
    }

    // Frames 서브컬렉션 (A타입 6개)
    let framesA: [[String: Any]] = [
        [
            "id": "A1",
            "name": "기본",
            "type": "A",
            "frameURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FSpeechBubble%2FFrameBody%2FA1.png?alt=media&token=88cac54f-2743-4b12-a131-ad8070d23010",
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FSpeechBubble%2FFrameThumbnail%2FA1.png?alt=media&token=451d19db-baba-4e0f-bda8-6fc902b13af8",
            "order": 1
        ]
    ]

    // Frames 서브컬렉션 (B타입 5개)
    let framesB: [[String: Any]] = [
        [
            "id": "B1",
            "name": "긴 기본",
            "type": "B",
            
            
            "frameURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FSpeechBubble%2FFrameBody%2FB1.png?alt=media&token=5f063fb8-415c-47b5-84de-edb9a5223d64",
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FSpeechBubble%2FFrameThumbnail%2FB1.png?alt=media&token=4bcf1d6e-6c9e-4eae-8484-06d8daf2c902",
            "order": 7
        ]
    ]

    // Frames 서브컬렉션 (C타입 4개)
    let framesC: [[String: Any]] = [
        [
            "id": "C1",
            "name": "별",
            "type": "C",
            
            
            "frameURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FSpeechBubble%2FFrameBody%2FC1.png?alt=media&token=9406ace2-bfb3-4922-a158-1e1cc46172ec",
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FSpeechBubble%2FFrameThumbnail%2FC1.png?alt=media&token=ed0e44ca-56c6-4b7d-8fe8-b8684a83b505",
            "order": 12
        ]
    ]

    let allFrames = framesA + framesB + framesC

    for frame in allFrames {
        guard let id = frame["id"] as? String else { continue }

        var data = frame
        data.removeValue(forKey: "id")

        do {
            try await db.collection("Template")
                .document("SpeechBubble")
                .collection("Frames")
                .document(id)
                .setData(data, merge: true)

            print("Frame \(id) 생성 완료")
        } catch {
            print("Frame \(id) 생성 오류: \(error)")
        }
    }
}

