import Foundation

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
}
