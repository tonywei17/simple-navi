import SwiftUI

struct ContentView: View {
    @State private var isFirstLaunch = true
    @State private var showSettings = false
    
    var body: some View {
        Group {
            if isFirstLaunch {
                // 首次进入使用 SetupView（无返回按钮）
                SetupView(isFirstLaunch: $isFirstLaunch, showSettings: $showSettings)
            } else {
                // 主页面
                CompassView(showSettings: $showSettings)
            }
        }
        // 从主页面进入设置：以全屏弹出，避免与顶部导航、滚动层交互冲突
        .fullScreenCover(isPresented: $showSettings) {
            SetupView(isFirstLaunch: $isFirstLaunch, showSettings: $showSettings)
        }
        .onAppear {
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: UDKeys.hasSetupAddresses)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}