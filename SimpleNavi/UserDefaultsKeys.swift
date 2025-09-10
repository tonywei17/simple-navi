import Foundation

/// Centralized UserDefaults keys to avoid magic strings and typos.
enum UDKeys {
    static let address1 = "address1"
    static let address2 = "address2"
    static let address3 = "address3"
    static let hasSetupAddresses = "hasSetupAddresses"
    static let isFirstLaunch = "isFirstLaunch" // Kept for backward compatibility
    static let selectedLanguage = "selectedLanguage"
}
