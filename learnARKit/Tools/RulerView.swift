//
//  RulerView.swift
//  learnARKit
//
//  Created by Tony on 2025/6/12.
//

import SwiftUI // 引入 SwiftUI 框架，用于构建界面
import RealityKit // 引入 RealityKit 框架，用于构建 AR 内容
import ARKit // 引入 ARKit 框架，用于访问 AR 功能

struct RulerView: View { // 定义 ContentView 结构体，遵循 View 协议
    var body: some View { // 定义视图的主体内容
        ARRulerViewContainer() // 显示 ARViewContainer 视图
            .edgesIgnoringSafeArea(.all) // 让 AR 视图铺满整个屏幕区域
    }
}

struct ARRulerViewContainer: UIViewRepresentable { // 定义 ARViewContainer 结构体，实现 UIViewRepresentable 协议，将 ARView 集成到 SwiftUI
    func makeUIView(context: Context) -> ARView { // 创建并配置 ARView
        let arView = ARView(frame: .zero) // 创建 ARView 实例，初始大小为零
        
        let config = ARWorldTrackingConfiguration() // 创建世界跟踪配置对象
        config.planeDetection = [.horizontal] // 启用水平面检测
        config.environmentTexturing = .automatic // 启用环境纹理自动生成
        arView.session.run(config, options: []) // 启动 AR 会话，应用配置
        
        context.coordinator.arView = arView // 将 ARView 实例赋值给协调器，便于后续操作
        arView.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))) // 添加点击手势识别器，触发 handleTap 方法
        
        return arView // 返回配置好的 ARView
    }

    func updateUIView(_ uiView: ARView, context: Context) {} // 更新 UIView 的方法，这里不需要实现

    func makeCoordinator() -> Coordinator { // 创建协调器对象
        return Coordinator() // 返回 Coordinator 实例
    }

    class Coordinator: NSObject { // 定义 Coordinator 类，继承自 NSObject
        weak var arView: ARView? // 弱引用 ARView，防止循环引用
        var points: [SIMD3<Float>] = [] // 存储点击选中的点的坐标
        var modelsArr: [Entity] = []

        @objc func handleTap(_ sender: UITapGestureRecognizer) { // 点击手势事件处理方法
            guard let arView = arView else { return } // 确保arView存在，否则返回
            let location = sender.location(in: arView) // 获取点击位置在arView中的坐标
            if let result = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal).first { // 从点击位置发射射线，检测水平平面
                let position = result.worldTransform.translation // 获取射线命中点的世界坐标
                points.append(position) // 将命中点坐标添加到points数组

                let sphere = ModelEntity(mesh: .generateSphere(radius: 0.005), materials: [SimpleMaterial(color: .red, isMetallic: false)]) // 创建一个红色小球模型实体
                let anchor = AnchorEntity(world: position) // 创建一个锚点实体，位置为命中点
                anchor.addChild(sphere) // 将小球添加到锚点实体
                arView.scene.addAnchor(anchor) // 将锚点添加到场景中显示小球
                modelsArr.append(sphere)

                if points.count == 2 { // 如果已经选中了两个点
                    drawLineAndDistance() // 绘制连接线并显示距离
                    points.removeAll() // 清空点数组，准备下一次测量
                    for model in modelsArr {
                        model.removeFromParent()
                    }
                    modelsArr.removeAll()
                }
            }
        }

        func drawLineAndDistance() {
            guard let arView = arView, points.count == 2 else { return }

            let start = points[0]
            let end = points[1]
            let distance = simd_distance(start, end)

            // 计算中点和方向
            let midPoint = (start + end) / 2
            let direction = normalize(end - start)

            // 生成线段模型
            let lineMesh = MeshResource.generateBox(size: [distance, 0.002, 0.002])
            let lineMaterial = SimpleMaterial(color: .blue, isMetallic: false)
            let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])

            // 构造朝向方向的旋转矩阵（Z轴默认朝前，这里我们需要让X轴对齐方向）
            let axis = simd_cross(SIMD3<Float>(1, 0, 0), direction)
            let angle = acos(dot(SIMD3<Float>(1, 0, 0), direction))
            let rotation = simd_quatf(angle: angle, axis: axis)
            lineEntity.transform = Transform(scale: .one, rotation: rotation, translation: midPoint)

            let lineAnchor = AnchorEntity(world: .zero)
            lineAnchor.addChild(lineEntity)
            arView.scene.addAnchor(lineAnchor)

            // 添加文字
            let textMesh = MeshResource.generateText(String(format: "%.2f m", distance),
                                                     extrusionDepth: 0.01,
                                                     font: .systemFont(ofSize: 0.1),
                                                     containerFrame: .zero,
                                                     alignment: .center,
                                                     lineBreakMode: .byWordWrapping)
            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
            textEntity.scale = SIMD3<Float>(repeating: 0.3)
            textEntity.position = midPoint + SIMD3<Float>(0, 0.05, 0) // 抬高一点以免遮挡

            lineAnchor.addChild(textEntity)
        }
    }
}

extension simd_float4x4 { // 扩展 simd_float4x4 类型
    var translation: SIMD3<Float> { // 添加 translation 计算属性，用于提取变换矩阵的平移部分
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z) // 返回平移向量
    }
}
