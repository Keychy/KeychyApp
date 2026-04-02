//
//  KeyringBodyComponent.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/18/25.
//

import UIKit
import SpriteKit

// MARK: - Keyring Body Component
struct KeyringBodyComponent {

    // MARK: - UIImage로 노드 생성
    static func createNode(
        from bodyImage: UIImage,
        templateId: String,
        isGyroscope: Bool = false,
        completion: @escaping (SKNode?) -> Void
    ) {
        let node = createImageBody(image: bodyImage, templateId: templateId, isGyroscope: isGyroscope)
        completion(node)
    }

    // MARK: - String URL로 노드 생성 (비동기)
    static func createNode(
        from bodyImageURL: String,
        templateId: String,
        isGyroscope: Bool = false,
        shimmerColorId: String? = nil,
        borderColorId: String? = nil,
        completion: @escaping (SKNode?) -> Void
    ) {
        Task {
            do {
                let image = try await StorageManager.shared.getImage(path: bodyImageURL)

                await MainActor.run {
                    let node = createImageBody(image: image, templateId: templateId, isGyroscope: isGyroscope, shimmerColorId: shimmerColorId, borderColorId: borderColorId)
                    completion(node)
                }
            } catch {
                print("Body 이미지 로드 실패: \(error)")

                await MainActor.run {
                    let node = createBasicBody()
                    completion(node)
                }
            }
        }
    }

    // MARK: - BodyType으로 노드 생성
    static func createNode(from bodyType: BodyType, templateId: String, isGyroscope: Bool = false) -> SKNode {
        switch bodyType {
        case .basic:
            return createBasicBody()
        case .customImage(let image):
            return createImageBody(image: image, templateId: templateId, isGyroscope: isGyroscope)
        }
    }

    // MARK: - Basic Body
    private static func createBasicBody() -> SKShapeNode {
        let radius: CGFloat = 80

        let path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)

        let node = SKShapeNode(path: path)
        node.fillColor = .white
        node.strokeColor = UIColor(white: 0.8, alpha: 0.4)
        node.lineWidth = 1.0
        node.zPosition = -1

        let physicsBody = SKPhysicsBody(circleOfRadius: radius - 2)
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = true
        physicsBody.mass = 3.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.6
        physicsBody.angularDamping = 0.9
        node.physicsBody = physicsBody

        return node
    }

    // MARK: - Image Body (KeyringScale 사용)
    private static func createImageBody(image: UIImage, templateId: String, isGyroscope: Bool = false, shimmerColorId: String? = nil, borderColorId: String? = nil) -> SKNode {
        // 자이로 템플릿: 아틀라스를 셰이더 적용 바디로 생성
        if isGyroscope {
            let shimmer = KeyringAppearanceColor.from(id: shimmerColorId)
            // borderColorId가 nil이면 shimmerColorId와 동일하게 사용 (하위 호환)
            let border = KeyringAppearanceColor.from(id: borderColorId ?? shimmerColorId)
            return createLenticularBody(
                atlasImage: image,
                templateId: templateId,
                shimmerColor: shimmer.shaderColor,
                shimmerMode: shimmer.shaderMode,
                borderColor: border.shaderColor,
                borderMode: border.shaderMode
            )
        }

        let maxSize = KeyringScale.maxSize(for: templateId)
        let originalSize = image.size

        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let scale = min(widthRatio, heightRatio, 1.0)

        let displaySize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let spriteNode = SKSpriteNode(texture: texture, size: displaySize)
        spriteNode.zPosition = -1

        let physicsBody = SKPhysicsBody(rectangleOf: displaySize)
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = true
        physicsBody.mass = 6.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        spriteNode.physicsBody = physicsBody

        return spriteNode
    }

    // MARK: - Lenticular Body (셰이더 적용)
    /// 아틀라스 텍스처를 maxSize로 강제 표시하고 LenticularShader 적용
    /// - 셰이더가 UV 좌/우 절반을 분리 샘플링하여 렌티큘러 효과 생성
    /// - 라운드 코너 + 메탈릭 테두리 + tilt 연동 밝기 변화 전부 셰이더에서 처리
    /// - shimmerColor/shimmerMode: 시머 색상 커스터마이징 (기본값 실버)
    static func createLenticularBody(
        atlasImage: UIImage,
        templateId: String,
        shimmerColor: (r: Float, g: Float, b: Float) = (0.85, 0.85, 0.85),
        shimmerMode: Float = 0.0,
        borderColor: (r: Float, g: Float, b: Float) = (0.85, 0.85, 0.85),
        borderMode: Float = 0.0
    ) -> SKSpriteNode {
        let displaySize = KeyringScale.maxSize(for: templateId)

        let texture = SKTexture(image: atlasImage)
        texture.filteringMode = .linear
        let spriteNode = SKSpriteNode(texture: texture, size: displaySize)
        spriteNode.zPosition = -1

        // 셰이더 로드 + uniform 설정
        // 라운드 코너, 테두리 모두 셰이더 SDF로 처리 (별도 노드 없음)
        if let shaderPath = Bundle.main.path(forResource: "LenticularShader", ofType: "fsh"),
           let shaderSource = try? String(contentsOfFile: shaderPath, encoding: .utf8) {
            let shader = SKShader(source: shaderSource)
            shader.uniforms = [
                SKUniform(name: "u_tilt", float: 0.0),
                SKUniform(name: "u_direction", float: 0.35),
                SKUniform(name: "u_sprite_size", vectorFloat2: vector_float2(
                    Float(displaySize.width), Float(displaySize.height)
                )),
                SKUniform(name: "u_cornerRadius", float: 12.0),
                SKUniform(name: "u_shimmer_color", vectorFloat3: vector_float3(
                    shimmerColor.r, shimmerColor.g, shimmerColor.b
                )),
                SKUniform(name: "u_shimmer_mode", float: shimmerMode),
                SKUniform(name: "u_border_color", vectorFloat3: vector_float3(
                    borderColor.r, borderColor.g, borderColor.b
                )),
                SKUniform(name: "u_border_mode", float: borderMode)
            ]
            spriteNode.shader = shader
        }

        // 물리 바디
        let physicsBody = SKPhysicsBody(rectangleOf: displaySize)
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = true
        physicsBody.mass = 6.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        spriteNode.physicsBody = physicsBody

        return spriteNode
    }
}
