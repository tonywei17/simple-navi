//
//  AppIntent.swift
//  SimpleNaviWidgets
//
//  Created by Wenxin Wei on 2025/10/03.
//

import WidgetKit
import AppIntents

@available(iOS 17.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "SimpleNavi Configuration" }
    static var description: IntentDescription { "Configure the navigation widget." }
}
