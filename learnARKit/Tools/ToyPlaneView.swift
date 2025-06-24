//
//  ToyPlaneView.swift
//  learnARKit
//
//  Created by Tony on 2025/6/20.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ToyPlaneView: View {
    var body: some View {
        ToyPlaneViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ToyPlaneViewContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
            Coordinator()
        }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // 配置 AR 会话支持平面检测
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config, options: [])

        // 添加手势点击事件
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        context.coordinator.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}

        class Coordinator: NSObject {
            weak var arView: ARView?
            
            // MARK: - Helper: start spin animation
            private func startSpin(on modelEntity: ModelEntity) {
                if !modelEntity.availableAnimations.isEmpty {
                    modelEntity.availableAnimations.forEach { animation in
                        modelEntity.playAnimation(animation.repeat(duration: .infinity),
                                                  transitionDuration: 0.3,
                                                  startsPaused: false)
                    }
                } else {
                    // 自定义绕 Y 轴持续旋转动画
                    let spin = modelEntity.move(
                        to: Transform(rotation: simd_quatf(angle: .pi * 2,
                                                           axis: SIMD3<Float>(0, 1, 0))),
                        relativeTo: modelEntity,
                        duration: 4.0,
                        timingFunction: .linear
                    )
                    
                }
            }


            @objc func handleTap(_ sender: UITapGestureRecognizer) {
                guard let arView = arView else { return }
                let location = sender.location(in: arView)

                // 如果用户点击的是已放置的模型，则触发动画而不是再放一个
                if let tappedEntity = arView.entity(at: location) as? ModelEntity {
                    startSpin(on: tappedEntity)
                    return
                }

                
                // 进行射线检测
                if let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first {
                    let position = SIMD3<Float>(result.worldTransform.columns.3.x,
                                                result.worldTransform.columns.3.y,
                                                result.worldTransform.columns.3.z)

                    // 加载 usdz 模型
                    ModelEntity.loadModelAsync(named: "toy_biplane_realistic")
                        .sink(receiveCompletion: { completion in
                            if case let .failure(error) = completion {
                                print("模型加载失败: \(error.localizedDescription)")
                            }
                        }, receiveValue: { modelEntity in
                            let anchor = AnchorEntity(world: position)
                            anchor.addChild(modelEntity)
                            // 生成碰撞形状以支持点击检测
                            modelEntity.generateCollisionShapes(recursive: true)
                            arView.scene.anchors.append(anchor)
                            
//                            // 让模型具备交互手势：旋转、缩放、拖拽
//                            modelEntity.generateCollisionShapes(recursive: true)
//                            arView.installGestures([.rotation, .scale, .translation], for: modelEntity)
//
//                            // 播放模型自带动画（若存在），否则创建自定义持续旋转动画
//                            if !modelEntity.availableAnimations.isEmpty {
//                                modelEntity.availableAnimations.forEach { animation in
//                                    modelEntity.playAnimation(animation.repeat(duration: .infinity),
//                                                              transitionDuration: 0.3,
//                                                              startsPaused: false)
//                                }
//                            } else {
//                                // 自定义绕 Y 轴持续旋转动画
//                                let spin = modelEntity.move(
//                                    to: Transform(rotation: simd_quatf(angle: .pi * 2,
//                                                                       axis: SIMD3<Float>(0, 1, 0))),
//                                    relativeTo: modelEntity,
//                                    duration: 4.0,
//                                    timingFunction: .linear
//                                )
//                                
//                            }
                        })
                        .store(in: &cancellables)
                }
            }

            // 为异步加载保留引用
            var cancellables = Set<AnyCancellable>()
        }
}
