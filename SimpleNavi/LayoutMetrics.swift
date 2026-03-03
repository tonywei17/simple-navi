import SwiftUI

/// Centralized responsive layout metrics system.
/// All views read from `@Environment(\.layoutMetrics)` to get device-appropriate sizes.
struct LayoutMetrics: Equatable {

    // MARK: - Device Category

    enum DeviceCategory: Equatable {
        case phoneCompact   // iPhone portrait
        case phoneLandscape // iPhone landscape
        case padPortrait    // iPad portrait (regular width)
        case padLandscape   // iPad landscape (regular w + regular h)
    }

    let category: DeviceCategory

    // MARK: - Compass

    var compassOuterSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 320
        case .padPortrait: return 420
        case .padLandscape: return 460
        }
    }

    var compassInnerSize: CGFloat { compassOuterSize - 20 }

    var compassTickOffset: CGFloat { -(compassInnerSize / 2 - 15) }

    var compassDirectionOffset: CGFloat { -(compassInnerSize / 2 - 40) }

    var compassDirectionFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 28
        case .padPortrait, .padLandscape: return 34
        }
    }

    var compassArrowSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 84
        case .padPortrait, .padLandscape: return 100
        }
    }

    var compassCenterDotSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 12
        case .padPortrait, .padLandscape: return 16
        }
    }

    var compassStrokeWidth: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 2
        case .padPortrait, .padLandscape: return 3
        }
    }

    // MARK: - Typography

    var titleFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 36
        case .padPortrait, .padLandscape: return 44
        }
    }

    var headlineFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 28
        case .padPortrait, .padLandscape: return 34
        }
    }

    var bodyFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 24
        case .padPortrait, .padLandscape: return 28
        }
    }

    var captionFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 20
        case .padPortrait, .padLandscape: return 24
        }
    }

    var smallFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 18
        case .padPortrait, .padLandscape: return 22
        }
    }

    var distanceFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 32
        case .padPortrait, .padLandscape: return 38
        }
    }

    // MARK: - Spacing & Padding

    var cardPadding: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 20
        case .padPortrait, .padLandscape: return 28
        }
    }

    var sectionSpacing: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 30
        case .padPortrait, .padLandscape: return 40
        }
    }

    var horizontalMargin: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 20
        case .padPortrait: return 40
        case .padLandscape: return 60
        }
    }

    // MARK: - Content Width Constraints

    /// Max width for modal views (DonationView, LanguageSelectionView)
    var modalMaxWidth: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return .infinity
        case .padPortrait: return 540
        case .padLandscape: return 600
        }
    }

    /// Max width for SetupView content area
    var setupContentMaxWidth: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return .infinity
        case .padPortrait: return 680
        case .padLandscape: return 800
        }
    }

    // MARK: - Slot Switcher

    var slotIconSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 72
        case .padPortrait, .padLandscape: return 88
        }
    }

    var slotIconFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 28
        case .padPortrait, .padLandscape: return 34
        }
    }

    var slotLabelWidth: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 90
        case .padPortrait, .padLandscape: return 110
        }
    }

    var slotSpacing: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 28
        case .padPortrait, .padLandscape: return 40
        }
    }

    // MARK: - Map

    var mapMinHeight: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 250
        case .padPortrait: return 400
        case .padLandscape: return 500
        }
    }

    var mapMaxHeight: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 350
        case .padPortrait: return 550
        case .padLandscape: return 600
        }
    }

    var mapAspectRatio: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 1.1
        case .padPortrait, .padLandscape: return 1.4
        }
    }

    // MARK: - Buttons

    var buttonHeight: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 56
        case .padPortrait, .padLandscape: return 64
        }
    }

    var topBarButtonFontSize: CGFloat {
        switch category {
        case .phoneCompact, .phoneLandscape: return 20
        case .padPortrait, .padLandscape: return 22
        }
    }

    // MARK: - Derived Booleans

    var isIPad: Bool {
        category == .padPortrait || category == .padLandscape
    }

    var usesHorizontalCompassLayout: Bool {
        category == .padLandscape
    }

    // MARK: - Factory

    static func resolve(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        screenSize: CGSize
    ) -> LayoutMetrics {
        let category: DeviceCategory

        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, .regular):
            category = screenSize.width > screenSize.height ? .padLandscape : .padPortrait
        case (.compact, .compact):
            category = .phoneLandscape
        case (.compact, .regular):
            // Could be iPhone OR iPad Split View — check width
            category = screenSize.width > 700 ? .padPortrait : .phoneCompact
        default:
            category = .phoneCompact
        }

        return LayoutMetrics(category: category)
    }
}

// MARK: - Environment Key

private struct LayoutMetricsKey: EnvironmentKey {
    static let defaultValue = LayoutMetrics(category: .phoneCompact)
}

extension EnvironmentValues {
    var layoutMetrics: LayoutMetrics {
        get { self[LayoutMetricsKey.self] }
        set { self[LayoutMetricsKey.self] = newValue }
    }
}
