//
//  BoxView.swift
//  learnARKit
//
//  Created by Tony on 2025/6/20.
//

import SwiftUI
import RealityKit
import ARKit

struct BoxView: View {
    var body: some View {
        BoxViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct BoxViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // 配置 AR 会话
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        // 添加点击手势
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}

        func makeCoordinator() -> Coordinator {
            return Coordinator(self)
        }

        class Coordinator: NSObject {
            var container: BoxViewContainer

            init(_ container: BoxViewContainer) {
                self.container = container
            }

            @objc func handleTap(_ sender: UITapGestureRecognizer) {
                guard let arView = sender.view as? ARView else { return }
                let location = sender.location(in: arView)

                // 平面检测
                if let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first {
                    let anchor = AnchorEntity(world: result.worldTransform)

                    // 添加一个立方体
                    let box = ModelEntity(mesh: .generateBox(size: 0.1))
                    box.model?.materials = [SimpleMaterial(color: .blue, isMetallic: false)]
                    anchor.addChild(box)
                    arView.scene.addAnchor(anchor)
                }
            }
        }
}
