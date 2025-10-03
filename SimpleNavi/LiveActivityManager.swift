import Foundation
import os.log
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Manages the lifecycle of the SimpleNavi Live Activity (Dynamic Island)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    // 全局开关：禁用灵动岛/Live Activity 时置为 false
    private let isEnabled = false

    // Use an untyped storage to avoid @available on stored properties with lower deployment targets
    #if canImport(ActivityKit)
    private var anyActivity: Any?
    #endif
    private var lastUpdate: Date = .distantPast
    // 提升更新频率到 ~2Hz；并对大角度/大距离变化即时放行
    private let throttleInterval: TimeInterval = 0.5
    private var lastBearing: Double?
    private var lastDistance: Double?
    private var lastDisplay: Double?

    private init() {}

    func startIfAvailable(slot: Int, destinationLabel: String) {
        guard isEnabled else { return }
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            if let current = anyActivity as? Activity<SimpleNaviActivityAttributes> {
                if current.attributes.slot != slot {
                    end()
                } else {
                    return
                }
            }
            let attrs = SimpleNaviActivityAttributes(slot: slot, destinationLabel: destinationLabel)
            let state = SimpleNaviActivityAttributes.ContentState(
                distanceMeters: 0,
                bearingRelToDevice: 0,
                displayBearing: 0,
                lastUpdated: Date()
            )
            do {
                let newActivity = try Activity.request(attributes: attrs, contentState: state)
                anyActivity = newActivity
            } catch {
                os_log("LiveActivity start error: %{public}@", String(describing: error))
            }
        }
        #endif
    }

    func update(distanceMeters: Double, bearingRelToDevice: Double) {
        guard isEnabled else { return }
        // 节流与跃变放行：角度变化>6°或距离变化>10m 即时更新
        let now = Date()
        var shouldUpdate = now.timeIntervalSince(lastUpdate) >= throttleInterval
        if let lb = lastBearing, abs(bearingRelToDevice - lb) > 6 { shouldUpdate = true }
        if let ld = lastDistance, abs(distanceMeters - ld) > 10 { shouldUpdate = true }
        guard shouldUpdate else { return }
        lastUpdate = now
        lastBearing = bearingRelToDevice
        lastDistance = distanceMeters
        // 计算显示角度：只按最短角度差前进，避免跨越整圈
        let prev = lastDisplay ?? bearingRelToDevice
        let delta = shortestDelta(from: prev, to: bearingRelToDevice)
        let newDisplay = prev + delta
        lastDisplay = normalizeAngle(newDisplay)

        #if canImport(ActivityKit)
        if #available(iOS 16.1, *), let activity = anyActivity as? Activity<SimpleNaviActivityAttributes> {
            let state = SimpleNaviActivityAttributes.ContentState(
                distanceMeters: distanceMeters,
                bearingRelToDevice: bearingRelToDevice,
                displayBearing: lastDisplay ?? bearingRelToDevice,
                lastUpdated: now
            )
            Task { await activity.update(using: state) }
        }
        #endif
    }

    func end() {
        guard isEnabled else { return }
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *), let activity = anyActivity as? Activity<SimpleNaviActivityAttributes> {
            Task { await activity.end(dismissalPolicy: .immediate) }
            self.anyActivity = nil
        }
        #endif
    }

    // MARK: - Angle helpers
    private func normalizeAngle(_ a: Double) -> Double {
        var x = a.truncatingRemainder(dividingBy: 360)
        if x > 180 { x -= 360 }
        if x < -180 { x += 360 }
        return x
    }
    private func shortestDelta(from: Double, to: Double) -> Double {
        var delta = to - from
        delta = delta.truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return delta
    }
}
