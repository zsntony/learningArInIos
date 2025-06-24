import SwiftUI // 引入 SwiftUI 框架，用于构建界面
import RealityKit // 引入 RealityKit 框架，用于构建 AR 内容
import ARKit // 引入 ARKit 框架，用于访问 AR 功能

struct ContentView: View { // 定义 ContentView 结构体，遵循 View 协议
    var body: some View { // 定义视图的主体内容
        NavigationView {
            List {
                ZStack(alignment: .leading) {
                    NavigationLink(destination: RulerView()) {

                    }.padding().opacity(0)
                    HStack {
                        Text("AR尺子")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 8)
                }
                ZStack(alignment: .leading) {
                    NavigationLink(destination: BoxView()) {

                    }.opacity(0)
                    HStack {
                        Text("AR的Box")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 8)
                }
                ZStack(alignment: .leading) {
                    NavigationLink(destination: ToyPlaneView()) {

                    }.opacity(0)
                    HStack {
                        Text("AR的飞机模型")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("功能列表")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
