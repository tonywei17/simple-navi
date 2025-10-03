//
//  SimpleNaviWidgets.swift
//  SimpleNaviWidgets
//
//  Created by Wenxin Wei on 2025/10/03.
//

import WidgetKit
import SwiftUI
import Foundation

@available(iOS 17.0, *)
struct Provider: AppIntentTimelineProvider {
    // App Group and key must match the main app
    private let appGroupId = "group.com.simplenavi.shared"
    private let snapshotKey = "navi.snapshot.json"

    struct WidgetSnapshot: Codable {
        var slot: Int
        var destinationLabel: String
        var distanceMeters: Double
        var bearingRelToDevice: Double
        var lastUpdated: Date
    }

    func loadSnapshot() -> WidgetSnapshot? {
        guard let ud = UserDefaults(suiteName: appGroupId),
              let data = ud.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), distance: 123, bearing: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        if let snap = loadSnapshot() {
            return SimpleEntry(date: snap.lastUpdated, configuration: configuration, distance: snap.distanceMeters, bearing: snap.bearingRelToDevice)
        }
        return SimpleEntry(date: Date(), configuration: configuration, distance: 0, bearing: 0)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry: SimpleEntry
        if let snap = loadSnapshot() {
            entry = SimpleEntry(date: snap.lastUpdated, configuration: configuration, distance: snap.distanceMeters, bearing: snap.bearingRelToDevice)
        } else {
            entry = SimpleEntry(date: Date(), configuration: configuration, distance: 0, bearing: 0)
        }
        // Policy: .never so system keeps current snapshot until we push a reload
        return Timeline(entries: [entry], policy: .never)
    }
}

@available(iOS 17.0, *)
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let distance: Double
    let bearing: Double
}

@available(iOS 17.0, *)
struct SimpleNaviWidgetsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().strokeBorder(.blue.opacity(0.2), lineWidth: 2)
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .bold))
                    .rotationEffect(.degrees(entry.bearing - 45))
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        case .accessoryRectangular:
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .bold))
                    .rotationEffect(.degrees(entry.bearing - 45))
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("\(Int(entry.distance))m")
                    .font(.system(size: 16, weight: .semibold))
            }
        default:
            VStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 24, weight: .bold))
                    .rotationEffect(.degrees(entry.bearing - 45))
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("\(Int(entry.distance))m")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
    }
}

@available(iOS 17.0, *)
struct SimpleNaviWidgets: Widget {
    let kind: String = "SimpleNaviWidgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SimpleNaviWidgetsEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

@available(iOS 17.0, *)
extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    SimpleNaviWidgets()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, distance: 120, bearing: 0)
    SimpleEntry(date: .now, configuration: .starEyes, distance: 350, bearing: 45)
}
