//
//  SimpleNaviWidgetsControl.swift
//  SimpleNaviWidgets
//
//  Created by Wenxin Wei on 2025/10/03.
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct SimpleNaviWidgetsControl: ControlWidget {
    static let kind: String = "com.simplenavi.simplenavi.QuickNaviControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetButton(action: StartNavigationIntent(slot: 0)) {
                Label("回家", systemImage: "house.fill")
            }
        }
        .displayName("回家导航")
        .description("从控制中心一键开启回家导航。")
    }
}

@available(iOS 18.0, *)
extension SimpleNaviWidgetsControl {
    struct Value {
        var destinationName: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: ControlConfiguration) -> Value {
            Value(destinationName: "家")
        }

        func currentValue(configuration: ControlConfiguration) async throws -> Value {
            return Value(destinationName: "家")
        }
    }
}

@available(iOS 18.0, *)
struct ControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "目的地配置"
    
    @Parameter(title: "目的地", default: "家")
    var destination: String
}
