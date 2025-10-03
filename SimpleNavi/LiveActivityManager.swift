import Foundation
import os.log
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Manages the lifecycle of the SimpleNavi Live Activity (Dynamic Island)
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    #if canImport(ActivityKit)
    private var activity: Activity<SimpleNaviActivityAttributes>?
    #endif
    private var lastUpdate: Date = .distantPast
    private let throttleInterval: TimeInterval = 1.0 // ~1Hz

    private init() {}

    func startIfAvailable(slot: Int, destinationLabel: String) {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            // If already running, update attributes only when slot changes
            if let current = activity {
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
                lastUpdated: Date()
            )
            do {
                activity = try Activity.request(attributes: attrs, contentState: state)
            } catch {
                os_log("LiveActivity start error: %{public}@", String(describing: error))
            }
        }
        #endif
    }

    func update(distanceMeters: Double, bearingRelToDevice: Double) {
        // Throttle to ~1Hz
        let now = Date()
        guard now.timeIntervalSince(lastUpdate) >= throttleInterval else { return }
        lastUpdate = now

        #if canImport(ActivityKit)
        if #available(iOS 16.1, *), let activity {
            let state = SimpleNaviActivityAttributes.ContentState(
                distanceMeters: distanceMeters,
                bearingRelToDevice: bearingRelToDevice,
                lastUpdated: now
            )
            Task { await activity.update(using: state) }
        }
        #endif
    }

    func end() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *), let activity {
            Task { await activity.end(dismissalPolicy: .immediate) }
            self.activity = nil
        }
        #endif
    }
}
