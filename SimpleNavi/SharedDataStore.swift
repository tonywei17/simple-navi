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
final class SharedDataStore {
    static let appGroupId = "group.com.simplenavi.shared"
    static let shared = SharedDataStore()

    private let defaults: UserDefaults?
    private let snapshotKey = "navi.snapshot.json"

    private init() {
        self.defaults = UserDefaults(suiteName: Self.appGroupId)
    }

    func save(snapshot: NaviSnapshot) {
        guard let defaults else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: snapshotKey)
            defaults.synchronize()
            #if canImport(WidgetKit)
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            }
            #endif
        } catch {
            os_log("SharedDataStore encode error: %{public}@", String(describing: error))
        }
    }

    func load() -> NaviSnapshot? {
        guard let defaults, let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(NaviSnapshot.self, from: data)
    }
}
