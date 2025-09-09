import SwiftUI

struct ContentView: View {
    @State private var isFirstLaunch = true
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            if isFirstLaunch || showSettings {
                SetupViewSimple(isFirstLaunch: $isFirstLaunch, showSettings: $showSettings)
            } else {
                CompassView(showSettings: $showSettings)
            }
        }
        .onAppear {
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasSetupAddresses")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}