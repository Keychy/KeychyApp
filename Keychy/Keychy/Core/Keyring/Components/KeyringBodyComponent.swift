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
        completion: @escaping (SKNode?) -> Void
    ) {
        let node = createImageBody(image: bodyImage, templateId: templateId)
        completion(node)
    }

    // MARK: - String URL로 노드 생성 (비동기)
    static func createNode(
        from bodyImageURL: String,
        templateId: String,
        completion: @escaping (SKNode?) -> Void
    ) {
        Task {
            do {
                let image = try await StorageManager.shared.getImage(path: bodyImageURL)

                await MainActor.run {
                    let node = createImageBody(image: image, templateId: templateId)
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
    static func createNode(from bodyType: BodyType, templateId: String) -> SKNode {
        switch bodyType {
        case .basic:
            return createBasicBody()
        case .customImage(let image):
            return createImageBody(image: image, templateId: templateId)
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
    private static func createImageBody(image: UIImage, templateId: String) -> SKNode {
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
}
