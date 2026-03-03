import SwiftUI
import CoreLocation
import Combine
import Observation

@Observable
@MainActor
class CompassViewModel {
    struct Destination: Equatable {
        let address: String
        let coordinate: CLLocationCoordinate2D?  // nil 表示坐标未设置（避免用 (0,0) 误判赤道坐标）
        let slot: Int // 0, 1, 2

        static func == (lhs: Destination, rhs: Destination) -> Bool {
            lhs.address == rhs.address &&
            lhs.coordinate?.latitude == rhs.coordinate?.latitude &&
            lhs.coordinate?.longitude == rhs.coordinate?.longitude &&
            lhs.slot == rhs.slot
        }
    }

    // MARK: - Slot Key Helpers（消除重复三元运算符）

    private static func addressKey(for slot: Int) -> String {
        switch slot {
        case 0: return UDKeys.address1
        case 1: return UDKeys.address2
        default: return UDKeys.address3
        }
    }

    private static func latKey(for slot: Int) -> String {
        switch slot {
        case 0: return UDKeys.address1Lat
        case 1: return UDKeys.address2Lat
        default: return UDKeys.address3Lat
        }
    }

    private static func lonKey(for slot: Int) -> String {
        switch slot {
        case 0: return UDKeys.address1Lon
        case 1: return UDKeys.address2Lon
        default: return UDKeys.address3Lon
        }
    }

    var selectedDestinationIndex = 0
    var destinations: [Destination] = []
    var slotLabels: [String] = ["", "", ""]
    var distance: Double = 0
    var angle: Double = 0
    var arrowRotation: Double = 0
    var spinAngle: Double = 0
    var isSpinning: Bool = false
    var showSetupPrompt: Bool = false
    
    // 2026 Advanced Features
    var triggerAlignmentFeedback: Bool = false
    var isAssistiveAccessEnabled: Bool = false
    var displayHeading: Double = 0
    private var hasInitializedRotation = false
    private var hasValidDestination = false
    
    // Cached slot addresses for sync access in UI
    var slotAddresses: [String] = ["", "", ""]
    
    var angleEpsilon: Double = 0.12
    var arrowAnimDuration: Double = 0.10
    
    private let locationManager = LocationManager()
    private let geocodingService = GeocodingService.shared
    
    private var lastPublishedDistance: Double?
    private var lastPublishedBearing: Double?
    private let publishCoalesceInterval: TimeInterval = 0.5
    private var publishTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        locationManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDirection()
            }
            .store(in: &cancellables)
        
        locationManager.$currentHeading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.updateDisplayHeading(newValue)
                self?.updateArrowRotation()
                self?.schedulePublish()
            }
            .store(in: &cancellables)
    }
    
    private func updateDisplayHeading(_ newHeading: Double) {
        if !hasInitializedRotation {
            displayHeading = newHeading
            // 延迟初始化直到有有效目的地数据，避免 angle=0 时的箭头跳变
            guard hasValidDestination else { return }
            let target = angle - newHeading
            arrowRotation = target
            hasInitializedRotation = true
            return
        }
        
        let diff = wrapDelta(newHeading - (displayHeading.truncatingRemainder(dividingBy: 360)))
        displayHeading += diff
    }
    
    func onAppear() {
        Task {
            await reloadData()
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                locationManager.startLocationUpdates { _ in }
                locationManager.startHeadingUpdates()
            }
            applyActiveDisplayProfile()
        }
    }
    
    func onSettingsChange(isShowing: Bool) {
        if isShowing {
            locationManager.stopHeadingUpdates()
        } else {
            Task {
                await reloadData()
                locationManager.startHeadingUpdates()
                applyActiveDisplayProfile()
            }
        }
    }
    
    private func reloadData() async {
        await loadSlotData()
        await loadLabels()
        updateDirection()
        hasValidDestination = !destinations.isEmpty
    }

    private func loadSlotData() async {
        var newDestinations: [Destination] = []
        var newSlotAddresses: [String] = ["", "", ""]

        for slot in 0...2 {
            let key = Self.addressKey(for: slot)
            if let addr = await getAddress(forKey: key), !addr.isEmpty {
                newSlotAddresses[slot] = addr

                let coord: CLLocationCoordinate2D?
                if let latStr = await SecureStorage.shared.getString(forKey: Self.latKey(for: slot)),
                   let lonStr = await SecureStorage.shared.getString(forKey: Self.lonKey(for: slot)),
                   let lat = Double(latStr), let lon = Double(lonStr) {
                    coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                } else {
                    coord = nil
                    geocodeAndStoreAddress(addr, slot: slot)
                }
                newDestinations.append(Destination(address: addr, coordinate: coord, slot: slot))
            }
        }
        
        destinations = newDestinations
        slotAddresses = newSlotAddresses
        
        if selectedDestinationIndex >= destinations.count {
            selectedDestinationIndex = max(0, destinations.count - 1)
        }
    }

    func loadLabels() async {
        let l1 = await AddressLabelStore.load(slot: 1)
        let l2 = await AddressLabelStore.load(slot: 2)
        let l3 = await AddressLabelStore.load(slot: 3)
        slotLabels = [l1, l2, l3]
    }

    private func geocodeAndStoreAddress(_ address: String, slot: Int) {
        Task {
            if let coordinate = await geocodingService.geocodeAddress(address) {
                await SecureStorage.shared.setString(String(coordinate.latitude), forKey: Self.latKey(for: slot))
                await SecureStorage.shared.setString(String(coordinate.longitude), forKey: Self.lonKey(for: slot))

                if let index = self.destinations.firstIndex(where: { $0.slot == slot }) {
                    self.destinations[index] = Destination(address: address, coordinate: coordinate, slot: slot)
                    self.updateDirection()
                }
            }
        }
    }

    func updateDirection() {
        guard selectedDestinationIndex < destinations.count else { return }
        let dest = destinations[selectedDestinationIndex]

        let targetCoord = dest.coordinate ?? Coordinates.nagoyaCenter
        
        let currentCoord = locationManager.currentLocation?.coordinate ?? Coordinates.nagoyaStation
        distance = geocodingService.calculateDistance(from: currentCoord, to: targetCoord)
        angle = geocodingService.calculateBearing(from: currentCoord, to: targetCoord)
        updateArrowRotation()
        schedulePublish()
    }
    
    private func updateArrowRotation() {
        let target = angle - locationManager.currentHeading
        let diff = wrapDelta(target - (arrowRotation.truncatingRemainder(dividingBy: 360)))
        
        arrowRotation += diff
        
        // Trigger haptic feedback if aligned (within 2 degrees of top)
        let threshold = 2.0
        let currentRelativeAngle = abs(wrapDelta(target))
        if currentRelativeAngle < threshold {
            if !triggerAlignmentFeedback {
                triggerAlignmentFeedback = true
                // Feedback is triggered in View via sensoryFeedback
                
                // Auto-reset after a short delay to allow re-triggering
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.triggerAlignmentFeedback = false
                }
            }
        } else {
            // Reset if moved out of the alignment zone
            if triggerAlignmentFeedback {
                triggerAlignmentFeedback = false
            }
        }
    }

    func wrapDelta(_ delta: Double) -> Double {
        var d = delta.truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    private func schedulePublish() {
        publishTask?.cancel()

        guard selectedDestinationIndex < destinations.count else { return }
        let distanceVal = distance
        let angleVal = angle
        let headingVal = locationManager.currentHeading
        let dest = destinations[selectedDestinationIndex]
        let label = labelForSlot(dest.slot)
        let slot = dest.slot

        publishTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self else { return }

            let bearingRel = self.wrapDelta(angleVal - headingVal)
            let distDiff = abs(distanceVal - (self.lastPublishedDistance ?? distanceVal))
            let bDiff = abs(self.wrapDelta(bearingRel - (self.lastPublishedBearing ?? bearingRel)))
            if distDiff < 1.0 && bDiff < 0.5 { return }

            let snapshot = NaviSnapshot(
                slot: slot,
                destinationLabel: label,
                distanceMeters: distanceVal,
                bearingRelToDevice: bearingRel,
                lastUpdated: Date()
            )
            await SharedDataStore.shared.save(snapshot: snapshot)
            self.lastPublishedDistance = distanceVal
            self.lastPublishedBearing = bearingRel

            LiveActivityManager.shared.startIfAvailable(slot: slot, destinationLabel: label)
            LiveActivityManager.shared.update(distanceMeters: distanceVal, bearingRelToDevice: bearingRel)
        }
    }

    func selectSlot(_ slotIndex: Int) {
        if let index = destinations.firstIndex(where: { $0.slot == slotIndex }) {
            selectedDestinationIndex = index
            updateDirection()
        } else {
            showSetupPrompt = true
        }
    }

    func spinArrow() {
        guard !isSpinning else { return }
        isSpinning = true
        spinAngle = 0
        withAnimation(.interpolatingSpring(stiffness: 120, damping: 10)) {
            spinAngle = 360
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.spinAngle = 0
            self.isSpinning = false
        }
    }

    private func applyActiveDisplayProfile() {
        let fps = UIScreen.main.maximumFramesPerSecond
        let isProMotion = fps >= 120
        angleEpsilon = isProMotion ? 0.06 : 0.10
        arrowAnimDuration = isProMotion ? 0.07 : 0.10
        locationManager.setHeadingFilter(0.5)
    }

    private func applyPassiveDisplayProfile() {
        angleEpsilon = 0.18
        arrowAnimDuration = 0.12
        locationManager.setHeadingFilter(1.5)
    }

    func labelForSlot(_ slot: Int) -> String {
        let index = max(0, min(slot, 2))
        let saved = slotLabels.indices.contains(index) ? slotLabels[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
        return saved.isEmpty ? AddressLabelStore.defaultLabel(for: index + 1) : saved
    }

    private func getAddress(forKey key: String) async -> String? {
        if let secured = await SecureStorage.shared.getString(forKey: key), !secured.isEmpty {
            return secured
        }
        return UserDefaults.standard.string(forKey: key)
    }

    func currentSlotIndex() -> Int {
        guard selectedDestinationIndex < destinations.count else { return 0 }
        return destinations[selectedDestinationIndex].slot
    }
    
    var currentHeading: Double {
        locationManager.currentHeading
    }
    
    func onScenePhaseChange(to phase: ScenePhase) {
        switch phase {
        case .active:
            applyActiveDisplayProfile()
        case .inactive, .background:
            applyPassiveDisplayProfile()
        @unknown default:
            break
        }
    }
}
