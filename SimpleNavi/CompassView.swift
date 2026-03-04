import SwiftUI
import CoreLocation

struct CompassView: View {
    @Binding var showSettings: Bool
    // @State with @Observable class is the recommended pattern (WWDC23 "Discover Observation in SwiftUI")
    @State private var viewModel = CompassViewModel()
    private var localizationManager = LocalizationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityAssistiveAccessEnabled) private var assistiveAccessEnabled
    @Environment(\.layoutMetrics) private var metrics
    @State private var showDonation = false

    init(showSettings: Binding<Bool>) {
        self._showSettings = showSettings
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView

                if metrics.usesHorizontalCompassLayout {
                    iPadLandscapeLayout
                } else {
                    verticalLayout
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if !viewModel.isAssistiveAccessEnabled {
                topBar
            }
        }
        .onAppear {
            viewModel.onAppear()
            viewModel.isAssistiveAccessEnabled = assistiveAccessEnabled
        }
        .onChange(of: showSettings) { _, newValue in
            viewModel.onSettingsChange(isShowing: newValue)
        }
        .onChange(of: scenePhase) { _, phase in
            viewModel.onScenePhaseChange(to: phase)
        }
        .onChange(of: assistiveAccessEnabled) { _, newValue in
            viewModel.isAssistiveAccessEnabled = newValue
        }
        .sheet(isPresented: $showDonation) {
            DonationView(isPresented: $showDonation)
        }
        .alert(String(localized: .locationNotSetTitle), isPresented: Binding(get: { viewModel.showSetupPrompt }, set: { viewModel.showSetupPrompt = $0 })) {
            Button(String(localized: .cancel), role: .cancel) {}
            Button(String(localized: .setupNow)) {
                showSettings = true
            }
        } message: {
            Text(String(localized: .locationNotSetMessage))
        }
    }

    // MARK: - iPad Landscape: Horizontal Split

    private var iPadLandscapeLayout: some View {
        HStack(spacing: 0) {
            VStack {
                Spacer()
                compassRing
                Spacer()
            }
            .frame(maxWidth: .infinity)

            ScrollView {
                VStack(spacing: metrics.sectionSpacing) {
                    if !viewModel.isAssistiveAccessEnabled {
                        destinationCard
                    }

                    distanceCard

                    if !viewModel.isAssistiveAccessEnabled {
                        destinationIconSwitcher
                            .padding(.horizontal, metrics.horizontalMargin)
                    }
                }
                .padding(.vertical, metrics.cardPadding)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Vertical Layout (iPhone + iPad Portrait)

    private var verticalLayout: some View {
        ScrollView {
            VStack(spacing: metrics.sectionSpacing) {
                if !viewModel.isAssistiveAccessEnabled {
                    destinationCard
                }

                compassRing
                    .padding(.horizontal, metrics.horizontalMargin)

                distanceCard

                if !viewModel.isAssistiveAccessEnabled {
                    destinationIconSwitcher
                        .padding(.horizontal, metrics.horizontalMargin)
                        .padding(.bottom, 8)
                }

                Color.clear.frame(height: 30)
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color(uiColor: .systemBackground)

            LinearGradient(
                colors: [
                    DesignTokens.bgGradientStart,
                    DesignTokens.bgGradientMiddle,
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(DesignTokens.bgAmbient)
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 150, y: 300)
        }
        .ignoresSafeArea()
    }

    // MARK: - Compass Ring (Responsive)

    private var compassRing: some View {
        let outerSize = viewModel.isAssistiveAccessEnabled
            ? metrics.compassOuterSize + 40
            : metrics.compassOuterSize

        return ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [DesignTokens.accent.opacity(DesignTokens.ringStrokeOpacity), DesignTokens.accentDeep.opacity(DesignTokens.ringStrokeOpacity)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: metrics.compassStrokeWidth
                )
                .frame(width: outerSize, height: outerSize)

            // Inner circle background
            Group {
                if #available(iOS 26.0, *) {
                    Circle()
                        .fill(.clear)
                        .frame(width: metrics.compassInnerSize, height: metrics.compassInnerSize)
                        .glassEffect(.regular, in: Circle())
                } else {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: metrics.compassInnerSize, height: metrics.compassInnerSize)
                        .overlay(
                            Circle()
                                .stroke(DesignTokens.accent.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(DesignTokens.shadowOpacity), radius: 20, x: 0, y: 10)
                }
            }

            // Ticks and direction labels
            Group {
                ForEach(0..<12) { tick in
                    Rectangle()
                        .fill(tick % 3 == 0 ? Color.primary.opacity(DesignTokens.tickMajorOpacity) : Color.primary.opacity(DesignTokens.tickMinorOpacity))
                        .frame(
                            width: tick % 3 == 0 ? 2 : 1,
                            height: tick % 3 == 0 ? (metrics.isIPad ? 20 : 15) : (metrics.isIPad ? 12 : 8)
                        )
                        .offset(y: metrics.compassTickOffset)
                        .rotationEffect(.degrees(Double(tick) * 30))
                }

                ForEach(0..<4) { index in
                    let directions = ["N", "E", "S", "W"]
                    let angles = [0.0, 90.0, 180.0, 270.0]
                    Text(directions[index])
                        .font(.system(size: metrics.compassDirectionFontSize, weight: .black, design: .rounded))
                        .foregroundColor(directions[index] == "N" ? DesignTokens.northRed : .primary.opacity(DesignTokens.directionLabelOpacity))
                        .offset(y: metrics.compassDirectionOffset)
                        .rotationEffect(.degrees(angles[index]))
                }
            }
            .rotationEffect(.degrees(-viewModel.displayHeading))
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.7, blendDuration: 0), value: viewModel.displayHeading)

            // Center dot
            Circle()
                .fill(DesignTokens.accent)
                .frame(width: metrics.compassCenterDotSize, height: metrics.compassCenterDotSize)
                .shadow(color: DesignTokens.accent.opacity(0.4), radius: 4)

            // Arrow
            CompassArrow(rotation: viewModel.arrowRotation + viewModel.spinAngle, size: metrics.compassArrowSize)
                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.7, blendDuration: 0), value: viewModel.arrowRotation)
                .contentShape(Circle())
                .onTapGesture {
                    viewModel.spinArrow()
                }
                .compositingGroup()
                .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: viewModel.triggerAlignmentFeedback) { _, new in
                    return new == true
                }
        }
    }

    // MARK: - Destination Card

    @ViewBuilder
    private var destinationCard: some View {
        if !viewModel.destinations.isEmpty && viewModel.selectedDestinationIndex < viewModel.destinations.count {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.system(size: metrics.headlineFontSize))
                        .foregroundColor(DesignTokens.accent)
                    Text(localized: .destination)
                        .font(.system(size: metrics.bodyFontSize, weight: .bold))
                        .foregroundColor(DesignTokens.textSecondary)
                    Spacer()
                }

                Text(viewModel.destinations[viewModel.selectedDestinationIndex].address)
                    .font(.system(size: metrics.headlineFontSize, weight: .bold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(metrics.cardPadding)
            .frame(maxWidth: .infinity)
            .glassCard()
            .shadow(color: .black.opacity(DesignTokens.shadowOpacity), radius: 10, x: 0, y: 5)
            .padding(.horizontal, metrics.horizontalMargin)
        }
    }

    // MARK: - Distance Card

    private var distanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "ruler")
                    .font(.system(size: metrics.bodyFontSize))
                    .foregroundColor(DesignTokens.accent)
                Text(localized: .distance)
                    .font(.system(size: metrics.captionFontSize, weight: .bold))
                    .foregroundColor(DesignTokens.textSecondary)
                Spacer()
            }

            if #available(iOS 16.0, *) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        distanceText
                        Text(localized: .meters)
                            .font(.system(size: metrics.headlineFontSize, weight: .bold))
                            .foregroundColor(DesignTokens.textSecondary)
                        Spacer(minLength: 0)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        distanceText
                        Text(localized: .meters)
                            .font(.system(size: metrics.headlineFontSize, weight: .bold))
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    distanceText
                    Text(localized: .meters)
                        .font(.system(size: metrics.headlineFontSize, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(metrics.cardPadding)
        .frame(maxWidth: .infinity)
        .glassCard()
        .shadow(color: .black.opacity(DesignTokens.shadowOpacity), radius: 15, x: 0, y: 5)
        .padding(.horizontal, metrics.horizontalMargin)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { showDonation = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: metrics.smallFontSize, weight: .bold))
                    Text(localized: .donate)
                        .font(.system(size: metrics.topBarButtonFontSize, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, metrics.cardPadding)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [DesignTokens.donatePrimary, DesignTokens.donateSecondary], startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: DesignTokens.donatePrimary.opacity(0.25), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: { showSettings = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: metrics.smallFontSize, weight: .bold))
                    Text(localized: .settings)
                        .font(.system(size: metrics.topBarButtonFontSize, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, metrics.cardPadding)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(DesignTokens.accent)
                )
                .shadow(color: DesignTokens.accent.opacity(0.25), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, metrics.horizontalMargin)
        .padding(.vertical, 6)
    }

    // MARK: - Distance Text

    private var distanceText: some View {
        Text("\(Int(viewModel.distance))")
            .font(.system(size: metrics.distanceFontSize, weight: .black, design: .rounded))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .foregroundStyle(LinearGradient(colors: [DesignTokens.accent, DesignTokens.accentDeep], startPoint: .leading, endPoint: .trailing))
            .animation(.easeInOut(duration: 0.3), value: viewModel.distance)
    }

    // MARK: - Destination Switcher

    private var destinationIconSwitcher: some View {
        HStack(spacing: metrics.slotSpacing) {
            ForEach(0..<3, id: \.self) { slot in
                let addr = viewModel.slotAddresses[slot]
                let isAvailable = !addr.isEmpty
                let isSelected = isAvailable && viewModel.currentSlotIndex() == slot

                Button(action: { viewModel.selectSlot(slot) }) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(slotGradient(slot))
                                .opacity(isAvailable ? 1.0 : 0.25)
                                .frame(width: metrics.slotIconSize, height: metrics.slotIconSize)
                                .overlay(
                                    Circle()
                                        .stroke(lineWidth: isSelected ? 5 : 0)
                                        .foregroundStyle(LinearGradient(colors: [DesignTokens.accent, DesignTokens.accentSubtle], startPoint: .leading, endPoint: .trailing))
                                )
                                .shadow(color: (isSelected ? DesignTokens.accent : Color.black).opacity(isAvailable ? 0.18 : 0.0), radius: isSelected ? 12 : 10, x: 0, y: 5)
                            Image(systemName: slotIconName(slot))
                                .foregroundColor(.white)
                                .font(.system(size: metrics.slotIconFontSize, weight: .bold))
                                .opacity(isAvailable ? 1.0 : 0.5)
                        }
                        Text(viewModel.labelForSlot(slot))
                            .font(.system(size: metrics.bodyFontSize, weight: .bold))
                            .foregroundColor(isAvailable ? Color(UIColor.label) : Color(UIColor.tertiaryLabel))
                            .frame(width: metrics.slotLabelWidth)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityShowsLargeContentViewer {
                    VStack(spacing: 12) {
                        Image(systemName: slotIconName(slot))
                            .font(.system(size: 60))
                        Text(viewModel.labelForSlot(slot))
                            .font(.system(size: 24, weight: .bold))
                    }
                }
            }
        }
        .padding(metrics.cardPadding)
        .glassCard()
        .shadow(color: .black.opacity(DesignTokens.shadowOpacity), radius: 10, x: 0, y: 4)
    }

    // MARK: - Helpers

    private func slotIconName(_ slot: Int) -> String {
        switch slot {
        case 0: return "house.fill"
        case 1: return "building.2.fill"
        default: return "heart.fill"
        }
    }

    private func slotGradient(_ slot: Int) -> LinearGradient {
        DesignTokens.slotGradient(slot)
    }
}

struct CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView(showSettings: .constant(false))
    }
}
