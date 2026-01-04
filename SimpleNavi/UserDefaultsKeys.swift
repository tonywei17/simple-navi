import Foundation
import SwiftUI

/// Centralized UserDefaults keys to avoid magic strings and typos.
enum UDKeys {
    static let address1 = "address1"
    static let address2 = "address2"
    static let address3 = "address3"
    static let hasSetupAddresses = "hasSetupAddresses"
    static let isFirstLaunch = "isFirstLaunch" // Kept for backward compatibility
    static let selectedLanguage = "selectedLanguage"

    // Persisted coordinates for each address slot
    static let address1Lat = "address1Lat"
    static let address1Lon = "address1Lon"
    static let address2Lat = "address2Lat"
    static let address2Lon = "address2Lon"
    static let address3Lat = "address3Lat"
    static let address3Lon = "address3Lon"
    static let address1Label = "address1Label"
    static let address2Label = "address2Label"
    static let address3Label = "address3Label"
}

enum AddressLabelStore {
    static func key(for slot: Int) -> String {
        switch slot {
        case 1: return UDKeys.address1Label
        case 2: return UDKeys.address2Label
        default: return UDKeys.address3Label
        }
    }

    static func defaultLabel(for slot: Int) -> String {
        switch slot {
        case 1: return String(localized: .home)
        case 2: return String(localized: .work)
        default: return String(localized: .other)
        }
    }

    static func load(slot: Int) async -> String {
        let key = key(for: slot)
        if let value = await SecureStorage.shared.getString(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            return value
        }
        return defaultLabel(for: slot)
    }

    static func save(_ label: String, slot: Int) async {
        let key = key(for: slot)
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultValue = defaultLabel(for: slot)
        if trimmed.isEmpty || trimmed == defaultValue {
            await SecureStorage.shared.remove(forKey: key)
        } else {
            await SecureStorage.shared.setString(trimmed, forKey: key)
        }
    }
}
