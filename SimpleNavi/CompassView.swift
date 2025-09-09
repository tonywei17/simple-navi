import SwiftUI
import CoreLocation

struct CompassView: View {
    @Binding var showSettings: Bool
    @StateObject private var locationManager = LocationManager()
    @StateObject private var geocodingService = GeocodingService.shared
    
    @State private var selectedDestination = 0
    @State private var addresses: [String] = []
    @State private var destinationCoordinates: [CLLocationCoordinate2D] = []
    @State private var angle: Double = 0
    @State private var distance: Double = 0
    
    private let destinationLabels = ["家", "地址2", "地址3"]
    
    var body: some View {
        VStack(spacing: 40) {
            HStack {
                Button("设置") {
                    showSettings = true
                }
                .font(.title2)
                .padding()
                
                Spacer()
            }
            
            if !addresses.isEmpty && selectedDestination < addresses.count {
                Text(addresses[selectedDestination])
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 300, height: 300)
                
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 280, height: 280)
                
                ForEach(0..<8) { tick in
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 2, height: 20)
                        .offset(y: -140)
                        .rotationEffect(.degrees(Double(tick) * 45))
                }
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(angle))
                    .animation(.easeInOut(duration: 0.5), value: angle)
            }
            
            VStack(spacing: 15) {
                Text("\(Int(distance))米")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                if addresses.count > 1 {
                    Picker("选择目的地", selection: $selectedDestination) {
                        ForEach(0..<min(addresses.count, 3), id: \.self) { index in
                            Text(destinationLabels[index])
                                .tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
        .onAppear {
            loadAddresses()
            startLocationUpdates()
        }
        .onChange(of: selectedDestination) { _ in
            updateDirection()
        }
    }
    
    private func loadAddresses() {
        var loadedAddresses: [String] = []
        var loadedCoordinates: [CLLocationCoordinate2D] = []
        
        if let addr1 = UserDefaults.standard.string(forKey: "address1"), !addr1.isEmpty {
            loadedAddresses.append(addr1)
            geocodeAndStoreAddress(addr1, index: loadedCoordinates.count)
            loadedCoordinates.append(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // 占位符
        }
        if let addr2 = UserDefaults.standard.string(forKey: "address2"), !addr2.isEmpty {
            loadedAddresses.append(addr2)
            geocodeAndStoreAddress(addr2, index: loadedCoordinates.count)
            loadedCoordinates.append(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // 占位符
        }
        if let addr3 = UserDefaults.standard.string(forKey: "address3"), !addr3.isEmpty {
            loadedAddresses.append(addr3)
            geocodeAndStoreAddress(addr3, index: loadedCoordinates.count)
            loadedCoordinates.append(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // 占位符
        }
        
        addresses = loadedAddresses
        destinationCoordinates = loadedCoordinates
    }
    
    private func geocodeAndStoreAddress(_ address: String, index: Int) {
        geocodingService.geocodeAddress(address) { [weak self] coordinate in
            guard let self = self, let coordinate = coordinate else { return }
            
            DispatchQueue.main.async {
                if index < self.destinationCoordinates.count {
                    self.destinationCoordinates[index] = coordinate
                    self.updateDirection()
                }
            }
        }
    }
    
    private func startLocationUpdates() {
        locationManager.startLocationUpdates { location in
            updateDirection()
        }
    }
    
    private func updateDirection() {
        guard selectedDestination < destinationCoordinates.count else { return }
        
        let destinationCoord = destinationCoordinates[selectedDestination]
        
        // 如果还没有获取到目标坐标，使用默认值
        guard destinationCoord.latitude != 0 && destinationCoord.longitude != 0 else {
            // 使用名古屋市中心作为默认位置进行演示
            let nagoyaCenter = CLLocationCoordinate2D(latitude: 35.1815, longitude: 136.9066)
            calculateDirectionAndDistance(to: nagoyaCenter)
            return
        }
        
        calculateDirectionAndDistance(to: destinationCoord)
    }
    
    private func calculateDirectionAndDistance(to destination: CLLocationCoordinate2D) {
        // 使用当前位置，如果没有则使用模拟位置（名古屋站附近）
        let currentCoord: CLLocationCoordinate2D
        if let current = locationManager.currentLocation?.coordinate {
            currentCoord = current
        } else {
            // 模拟位置：名古屋站
            currentCoord = CLLocationCoordinate2D(latitude: 35.1706, longitude: 136.8816)
        }
        
        // 计算距离（米）
        let calculatedDistance = geocodingService.calculateDistance(from: currentCoord, to: destination)
        distance = calculatedDistance
        
        // 计算方向角（度）
        let calculatedBearing = geocodingService.calculateBearing(from: currentCoord, to: destination)
        angle = calculatedBearing
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func startLocationUpdates(completion: @escaping (CLLocation) -> Void) {
        locationUpdateHandler = completion
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationUpdateHandler?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}

struct CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView(showSettings: .constant(false))
    }
}