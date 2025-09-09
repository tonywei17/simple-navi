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
        GeometryReader { geometry in
            ZStack {
                // 现代化渐变背景
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 顶部导航栏
                        HStack {
                            Spacer()
                            
                            Button(action: { showSettings = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("设置")
                                        .font(.system(size: 18, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.blue)
                                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 目的地卡片
                        if !addresses.isEmpty && selectedDestination < addresses.count {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                    Text("目的地")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                Text(addresses[selectedDestination])
                                    .font(.system(size: 20, weight: .semibold))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // 现代化指南针
                        ZStack {
                            // 外圆环
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 6
                                )
                                .frame(width: 320, height: 320)
                            
                            // 内圆背景
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.9),
                                            Color.blue.opacity(0.05)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 140
                                    )
                                )
                                .frame(width: 300, height: 300)
                                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                            
                            // 方向刻度
                            ForEach(0..<8) { tick in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        tick % 2 == 0 
                                        ? Color.primary.opacity(0.8)
                                        : Color.primary.opacity(0.4)
                                    )
                                    .frame(width: 3, height: tick % 2 == 0 ? 25 : 15)
                                    .offset(y: -140)
                                    .rotationEffect(.degrees(Double(tick) * 45))
                            }
                            
                            // 方向标识
                            ForEach(["N", "E", "S", "W"].indices, id: \.self) { index in
                                Text(["N", "E", "S", "W"][index])
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary.opacity(0.7))
                                    .offset(y: -120)
                                    .rotationEffect(.degrees(Double(index) * 90))
                            }
                            
                            // 中心点
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                                .shadow(color: .blue.opacity(0.5), radius: 4)
                            
                            // 现代化箭头
                            ZStack {
                                // 箭头阴影
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 70, weight: .bold))
                                    .foregroundColor(.black.opacity(0.1))
                                    .offset(x: 2, y: 2)
                                    .rotationEffect(.degrees(angle))
                                
                                // 主箭头
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 70, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .rotationEffect(.degrees(angle))
                                    .shadow(color: .red.opacity(0.3), radius: 8)
                            }
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: angle)
                        }
                        .padding(.horizontal, 20)
                        
                        // 距离显示卡片
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "ruler")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                                Text("距离")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            HStack {
                                Text("\(Int(distance))")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: distance)
                                
                                Text("米")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        
                        // 目的地选择器
                        if addresses.count > 1 {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                    Text("选择目的地")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                Picker("选择目的地", selection: $selectedDestination) {
                                    ForEach(0..<min(addresses.count, 3), id: \.self) { index in
                                        Text(destinationLabels[index])
                                            .font(.system(size: 18, weight: .medium))
                                            .tag(index)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .scaleEffect(1.1)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // 底部间距
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
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