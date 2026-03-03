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
                Label {
                    Text("Home", bundle: .main)
                } icon: {
                    Image(systemName: "house.fill")
                }
            }
        }
        .displayName(LocalizedStringResource("Quick Navigation", comment: "Control widget display name"))
        .description(LocalizedStringResource("Start home navigation from Control Center.", comment: "Control widget description"))
    }
}

@available(iOS 18.0, *)
extension SimpleNaviWidgetsControl {
    struct Value {
        var destinationName: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: ControlConfiguration) -> Value {
            Value(destinationName: "Home")
        }

        func currentValue(configuration: ControlConfiguration) async throws -> Value {
            return Value(destinationName: "Home")
        }
    }
}

@available(iOS 18.0, *)
struct ControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Destination Configuration"

    @Parameter(title: "Destination", default: "Home")
    var destination: String
}
