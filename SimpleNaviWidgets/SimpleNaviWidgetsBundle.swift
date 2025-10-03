//
//  SimpleNaviWidgetsBundle.swift
//  SimpleNaviWidgets
//
//  Created by Wenxin Wei on 2025/10/03.
//

import WidgetKit
import SwiftUI

@main
struct SimpleNaviWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 17.0, *) {
            SimpleNaviWidgets()
        }
        // iOS 18+ 才支持控制小组件（Control Widget）。降低部署版本时需做可用性判断。
        if #available(iOS 18.0, *) {
            SimpleNaviWidgetsControl()
        }
        // 已按需求禁用 Live Activity（灵动岛）展示，仅保留 Widget。
        // SimpleNaviWidgetsLiveActivity()
    }
}
