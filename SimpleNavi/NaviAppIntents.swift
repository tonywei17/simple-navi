import AppIntents
import CoreLocation

@available(iOS 16.0, *)
struct StartNavigationIntent: AppIntent {
    static var title: LocalizedStringResource = "开始导航"
    static var description = IntentDescription("开启指向特定地点的极简导航指引")
    
    @Parameter(title: "目的地", default: 0)
    var slot: Int
    
    init() {}
    
    init(slot: Int) {
        self.slot = slot
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("开始向目的地 \(\.$slot) 导航")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let safeSlot = max(0, min(slot, 2))
        let label = await AddressLabelStore.load(slot: safeSlot + 1)
        _ = await getAddress(for: safeSlot)
        return .result(dialog: "好的，已为你开启向\(label)的指引。")
    }

    private func getAddress(for slot: Int) async -> String {
        let key: String
        switch slot {
        case 0: key = UDKeys.address1
        case 1: key = UDKeys.address2
        default: key = UDKeys.address3
        }
        return await SecureStorage.shared.getString(forKey: key) ?? ""
    }
}

@available(iOS 16.0, *)
struct NaviShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartNavigationIntent(),
            phrases: [
                "用 \(.applicationName) 带我回家",
                "在 \(.applicationName) 中开始导航",
                "用 \(.applicationName) 开启回家指引"
            ],
            shortTitle: "开始导航",
            systemImageName: "location.fill"
        )
    }
}
