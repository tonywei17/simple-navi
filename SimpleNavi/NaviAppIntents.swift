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
        // 在实际应用中，这里会通过 App Group 或通知告知主应用切换目的地
        // 由于是极简导航，我们可以直接保存新的选择到 SharedDataStore
        let label = await AddressLabelStore.load(slot: slot + 1)
        let addr = await getAddress(for: slot)
        
        // 这里的逻辑可以根据主应用的运行状态决定是打开 App 还是仅更新后台数据
        // 对于 2026 年的 Apple Intelligence，建议返回一个简单的结果
        return .result(dialog: "好的，已为你开启向\(label)的指引。")
    }
    
    private func getAddress(for slot: Int) async -> String {
        let key = slot == 0 ? UDKeys.address1 : slot == 1 ? UDKeys.address2 : UDKeys.address3
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
