import Foundation
import os.log
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Snapshot model shared between App, Widgets, and Live Activities via App Group
struct NaviSnapshot: Codable, Equatable {
    var slot: Int
    var destinationLabel: String
    var distanceMeters: Double
    /// Bearing relative to device heading (degrees, -180...180). Positive means clockwise.
    var bearingRelToDevice: Double
    var lastUpdated: Date
}

/// Lightweight shared store using App Group UserDefaults
actor SharedDataStore {
    static let appGroupId = "group.com.simplenavi.shared"
    static let shared = SharedDataStore()

    private let defaults: UserDefaults?
    private let snapshotKey = "navi.snapshot.json"
    
    // 上一次成功写入的快照与时间
    private var lastSnapshot: NaviSnapshot?
    private var lastSaveTime: Date = .distantPast
    
    // 写入与刷新节流参数（根据体验/能耗折中）
    private let minSaveInterval: TimeInterval = 0.4
    private let distanceEpsilon: Double = 2.0 // 米
    private let bearingEpsilon: Double = 1.0  // 度
    
    #if canImport(WidgetKit)
    private var lastReloadTime: Date = .distantPast
    private var pendingReload = false
    private let widgetKind = "SimpleNaviWidgets"
    private let minReloadInterval: TimeInterval = 2.0
    #endif

    private init() {
        self.defaults = UserDefaults(suiteName: Self.appGroupId)
    }

    func save(snapshot: NaviSnapshot) {
        let now = Date()

        // 阈值判断：若变动极小且未到最小保存间隔，则忽略
        if let last = self.lastSnapshot {
            let distDiff = abs(snapshot.distanceMeters - last.distanceMeters)
            // 角度差归一化到 [-180, 180]
            var bearingDiff = snapshot.bearingRelToDevice - last.bearingRelToDevice
            bearingDiff = bearingDiff.truncatingRemainder(dividingBy: 360)
            if bearingDiff > 180 { bearingDiff -= 360 }
            if bearingDiff < -180 { bearingDiff += 360 }
            let isSameSlot = snapshot.slot == last.slot
            let isSameLabel = snapshot.destinationLabel == last.destinationLabel
            let trivialChange = distDiff < self.distanceEpsilon && abs(bearingDiff) < self.bearingEpsilon && isSameSlot && isSameLabel
            if trivialChange && now.timeIntervalSince(self.lastSaveTime) < self.minSaveInterval {
                return
            }
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(snapshot)
            defaults?.set(data, forKey: self.snapshotKey)
            self.lastSnapshot = snapshot
            self.lastSaveTime = now
        } catch {
            os_log("SharedDataStore encode error: %{public}@", String(describing: error))
        }

        // 节流刷新：仅刷新本 Widget 的时间线，并做 2s 合并
        #if canImport(WidgetKit)
        if #available(iOS 14.0, *) {
            let since = now.timeIntervalSince(self.lastReloadTime)
            if since >= self.minReloadInterval {
                self.lastReloadTime = now
                WidgetCenter.shared.reloadTimelines(ofKind: self.widgetKind)
            } else if !self.pendingReload {
                self.pendingReload = true
                let delay = max(0.25, self.minReloadInterval - since)
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await self.performReload()
                }
            }
        }
        #endif
    }
    
    #if canImport(WidgetKit)
    private func performReload() {
        self.pendingReload = false
        self.lastReloadTime = Date()
        WidgetCenter.shared.reloadTimelines(ofKind: self.widgetKind)
    }
    #endif

    func load() -> NaviSnapshot? {
        guard let defaults = self.defaults, let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(NaviSnapshot.self, from: data)
    }
}
