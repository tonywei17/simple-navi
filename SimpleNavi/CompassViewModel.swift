import SwiftUI
import CoreLocation
import Combine
import Observation

@Observable
@MainActor
class CompassViewModel {
    struct Destination: Equatable {
        let address: String
        let coordinate: CLLocationCoordinate2D
        let slot: Int // 0, 1, 2
        
        static func == (lhs: Destination, rhs: Destination) -> Bool {
            lhs.address == rhs.address &&
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude &&
            lhs.slot == rhs.slot
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
    
    // Cached slot addresses for sync access in UI
    var slotAddresses: [String] = ["", "", ""]
    
    var angleEpsilon: Double = 0.12
    var arrowAnimDuration: Double = 0.10
    
    private let locationManager = LocationManager()
    private let geocodingService = GeocodingService.shared
    
    private var lastPublishedDistance: Double = .nan
    private var lastPublishedBearing: Double = .nan
    private let publishCoalesceInterval: TimeInterval = 0.5
    private var publishWork: DispatchWorkItem?
    
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
            .sink { [weak self] _ in
                self?.updateArrowRotation()
                self?.schedulePublish()
            }
            .store(in: &cancellables)
    }
    
    func onAppear() {
        Task {
            await reloadData()
            setupAssistiveAccessObservation()
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                locationManager.startLocationUpdates { _ in }
                locationManager.startHeadingUpdates()
            }
            applyActiveDisplayProfile()
        }
    }
    
    private func setupAssistiveAccessObservation() {
        // iOS 18+ feature detection
        if #available(iOS 18.0, *) {
            // Initial check
            // self.isAssistiveAccessEnabled = UIAccessibility.isAssistiveAccessEnabled
            // In a real app, we would listen to UIAccessibility.assistiveAccessStatusDidChangeNotification
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
    }

    private func loadSlotData() async {
        var newDestinations: [Destination] = []
        var newSlotAddresses: [String] = ["", "", ""]
        
        for slot in 0...2 {
            let key = slot == 0 ? UDKeys.address1 : slot == 1 ? UDKeys.address2 : UDKeys.address3
            if let addr = await getAddress(forKey: key), !addr.isEmpty {
                newSlotAddresses[slot] = addr
                
                let latKey = slot == 0 ? UDKeys.address1Lat : slot == 1 ? UDKeys.address2Lat : UDKeys.address3Lat
                let lonKey = slot == 0 ? UDKeys.address1Lon : slot == 1 ? UDKeys.address1Lon : UDKeys.address3Lon
                
                let coord: CLLocationCoordinate2D
                if let latStr = await SecureStorage.shared.getString(forKey: latKey),
                   let lonStr = await SecureStorage.shared.getString(forKey: lonKey),
                   let lat = Double(latStr), let lon = Double(lonStr) {
                    coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                } else {
                    coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    // Trigger background geocoding if missing
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
                let latKey = slot == 0 ? UDKeys.address1Lat : slot == 1 ? UDKeys.address2Lat : UDKeys.address3Lat
                let lonKey = slot == 0 ? UDKeys.address1Lon : slot == 1 ? UDKeys.address2Lon : UDKeys.address3Lon
                await SecureStorage.shared.setString(String(coordinate.latitude), forKey: latKey)
                await SecureStorage.shared.setString(String(coordinate.longitude), forKey: lonKey)

                await MainActor.run {
                    // Update the destination in our list if it exists
                    if let index = self.destinations.firstIndex(where: { $0.slot == slot }) {
                        self.destinations[index] = Destination(address: address, coordinate: coordinate, slot: slot)
                        self.updateDirection()
                    }
                }
            }
        }
    }

    func updateDirection() {
        guard selectedDestinationIndex < destinations.count else { return }
        let dest = destinations[selectedDestinationIndex]
        
        let targetCoord: CLLocationCoordinate2D
        if dest.coordinate.latitude != 0 && dest.coordinate.longitude != 0 {
            targetCoord = dest.coordinate
        } else {
            targetCoord = Coordinates.nagoyaCenter
        }
        
        let currentCoord = locationManager.currentLocation?.coordinate ?? Coordinates.nagoyaStation
        distance = geocodingService.calculateDistance(from: currentCoord, to: targetCoord)
        angle = geocodingService.calculateBearing(from: currentCoord, to: targetCoord)
        updateArrowRotation()
        schedulePublish()
    }
    
    private func updateArrowRotation() {
        let target = angle - locationManager.currentHeading
        let diff = wrapDelta(target - arrowRotation)
        
        // Trigger haptic feedback if aligned (within 5 degrees)
        // Only trigger once when entering the alignment zone
        let threshold = 5.0
        if abs(wrapDelta(target)) < threshold && abs(wrapDelta(target - arrowRotation)) > 0.5 {
            if !triggerAlignmentFeedback {
                triggerAlignmentFeedback = true
                // Reset after a short delay to allow re-triggering if user moves away and back
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.triggerAlignmentFeedback = false
                }
            }
        }

        if abs(diff) < angleEpsilon { return }
        
        if isSpinning {
            arrowRotation += diff
        } else {
            withAnimation(.linear(duration: arrowAnimDuration)) {
                arrowRotation += diff
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
        publishWork?.cancel()
        let distanceVal = distance
        let angleVal = angle
        let headingVal = locationManager.currentHeading
        
        // Capture current state for the task
        guard selectedDestinationIndex < destinations.count else { return }
        let dest = destinations[selectedDestinationIndex]
        let label = labelForSlot(dest.slot)
        let slot = dest.slot

        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                let bearingRel = self.wrapDelta(angleVal - headingVal)

                let distDiff = abs(distanceVal - (self.lastPublishedDistance.isNaN ? distanceVal : self.lastPublishedDistance))
                var bDiff = bearingRel - (self.lastPublishedBearing.isNaN ? bearingRel : self.lastPublishedBearing)
                bDiff = bDiff.truncatingRemainder(dividingBy: 360)
                if distDiff < 1.0 && abs(bDiff) < 0.5 { return }

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
        publishWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + publishCoalesceInterval, execute: work)
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
