import SwiftUI
import CoreLocation

struct CompassView: View {
    @Binding var showSettings: Bool
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedDestination = 0
    @State private var addresses: [String] = []
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
        
        if let addr1 = UserDefaults.standard.string(forKey: "address1"), !addr1.isEmpty {
            loadedAddresses.append(addr1)
        }
        if let addr2 = UserDefaults.standard.string(forKey: "address2"), !addr2.isEmpty {
            loadedAddresses.append(addr2)
        }
        if let addr3 = UserDefaults.standard.string(forKey: "address3"), !addr3.isEmpty {
            loadedAddresses.append(addr3)
        }
        
        addresses = loadedAddresses
    }
    
    private func startLocationUpdates() {
        locationManager.startLocationUpdates { location in
            updateDirection()
        }
    }
    
    private func updateDirection() {
        // 这里需要实现方向计算逻辑
        // 暂时使用模拟数据
        angle = Double.random(in: 0...360)
        distance = Double.random(in: 100...5000)
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