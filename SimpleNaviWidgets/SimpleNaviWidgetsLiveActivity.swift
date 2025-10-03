//
//  SimpleNaviWidgetsLiveActivity.swift
//  SimpleNaviWidgets
//
//  Created by Wenxin Wei on 2025/10/03.
//

import ActivityKit
import WidgetKit
import SwiftUI

// 使用主 App 内共享的 Attributes/ContentState（文件被同时编译进扩展）
// SimpleNaviActivityAttributes.ContentState 包含：distanceMeters、bearingRelToDevice、lastUpdated

@available(iOS 16.1, *)
struct SimpleNaviWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SimpleNaviActivityAttributes.self) { context in
            // 锁屏/横幅样式：箭头 + 距离横向并排（容器 > 箭头，箭头自动最大化填充）
            HStack(alignment: .center, spacing: 8) {
                ArrowView(degrees: context.state.displayBearing)
                    .frame(width: 20, height: 20)
                    .clipped()
                HStack(spacing: 4) {
                    Text(Int(context.state.distanceMeters), format: .number)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("m")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                // 展开：箭头显著缩小 + 距离（容器 > 箭头，箭头自动最大化填充）
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        ArrowView(degrees: context.state.displayBearing)
                            .frame(width: 36, height: 36)
                            .clipped()
                        HStack(spacing: 6) {
                            Text(Int(context.state.distanceMeters), format: .number)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("m")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } compactLeading: {
                ArrowView(degrees: context.state.displayBearing)
                    .frame(width: 14, height: 14)
                    .clipped()
            } compactTrailing: {
                Text("\(Int(context.state.distanceMeters))m")
                    .font(.system(size: 12, weight: .semibold))
            } minimal: {
                ArrowView(degrees: context.state.displayBearing)
                    .frame(width: 10, height: 10)
                    .clipped()
            }
        }
    }
}

// 简单箭头视图：使用 SF Symbol 旋转绘制
@available(iOS 16.1, *)
private struct ArrowView: View {
    let degrees: Double // [-180, 180]
    var body: some View {
        GeometryReader { geo in
            let size = max(0, min(geo.size.width, geo.size.height)) // 0 边距，尽可能填满容器
            ZStack {
                Image(systemName: "location.fill")
                    .font(.system(size: size, weight: .bold))
                    .foregroundColor(.blue.opacity(0.12))
                    .rotationEffect(.degrees(degrees - 45))
                Image(systemName: "location.fill")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .rotationEffect(.degrees(degrees - 45))
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .accessibilityHidden(true)
    }
}
