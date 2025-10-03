import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Live Activities Attributes for SimpleNavi
struct SimpleNaviActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var distanceMeters: Double
        /// Bearing relative to device heading, degrees in [-180, 180]
        var bearingRelToDevice: Double
        var lastUpdated: Date
    }

    /// Destination slot index (0: Home, 1: Work, 2: Other)
    var slot: Int
    /// Localized destination label shown in UI
    var destinationLabel: String
}
#endif
