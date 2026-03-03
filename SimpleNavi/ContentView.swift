import SwiftUI

struct ContentView: View {
    @State private var isFirstLaunch: Bool
    @State private var showSettings = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init() {
        _isFirstLaunch = State(initialValue: !UserDefaults.standard.bool(forKey: UDKeys.hasSetupAddresses))
    }

    var body: some View {
        GeometryReader { geometry in
            let metrics = LayoutMetrics.resolve(
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass,
                screenSize: geometry.size
            )

            Group {
                if isFirstLaunch {
                    SetupView(isFirstLaunch: $isFirstLaunch, showSettings: $showSettings)
                } else {
                    CompassView(showSettings: $showSettings)
                }
            }
            .fullScreenCover(isPresented: $showSettings) {
                SetupView(isFirstLaunch: $isFirstLaunch, showSettings: $showSettings)
                    .environment(\.layoutMetrics, metrics)
            }
            .environment(\.layoutMetrics, metrics)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}