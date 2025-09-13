import SwiftUI
import CoreLocation
import UIKit

struct CompassView: View {
    @Binding var showSettings: Bool
    @StateObject private var locationManager = LocationManager()
    @StateObject private var geocodingService = GeocodingService.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var selectedDestination = 0
    @State private var addresses: [String] = []
    @State private var destinationCoordinates: [CLLocationCoordinate2D] = []
    @State private var angle: Double = 0
    @State private var distance: Double = 0
    @State private var showDonation = false
    @State private var spinOffset: Double = 0 // 点击箭头时用于做一圈旋转的增量角度
    @State private var arrowRotation: Double = 0 // 基于最短角度差的累计显示角度（不整圈）
    @State private var showSetupPrompt: Bool = false // 未设置地址时的提示弹窗
    
    
    private var destinationLabels: [String] {
        [
            String(localized: .home),
            String(localized: .work),
            String(localized: .other)
        ]
    }
    
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
                        
                        // 目的地卡片
                        if !addresses.isEmpty && selectedDestination < addresses.count {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                    Text(localized: .destination)
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
                            
                            // 罗盘刻度和方向标识（随设备旋转反向旋转以保持地理方向）
                            Group {
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
                                
                                // 方向标识 - 修复为正确的指南针方向
                                ForEach(0..<4) { index in
                                    let directions = ["N", "E", "S", "W"]
                                    let angles = [0.0, 90.0, 180.0, 270.0] // N上, E右, S下, W左
                                    Text(directions[index])
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary.opacity(0.7))
                                        .offset(y: -100)
                                        .rotationEffect(.degrees(angles[index]))
                                }
                            }
                            .rotationEffect(.degrees(-locationManager.currentHeading))
                            
                            // 中心点
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                                .shadow(color: .blue.opacity(0.5), radius: 4)
                            
                            // 现代化箭头 - 优先使用自定义图片资源，其次回退到 SF Symbol
                            // 使用累计的最短角度差显示值，避免自然转动手机时出现整圈旋转
                            CompassArrow(rotation: arrowRotation + spinOffset)
                                .contentShape(Circle())
                                .onTapGesture {
                                    // 趣味动效：点击时顺时针旋转一圈，带一点弹性
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.55, blendDuration: 0.2)) {
                                        spinOffset += 360
                                    }
                                }
                                // 位置/朝向变化的平滑动画（线性、短时长，连续平顺）
                                .animation(.linear(duration: 0.12), value: arrowRotation)
                                // 点击旋转动效的弹性动画
                                .animation(.spring(response: 0.6, dampingFraction: 0.55, blendDuration: 0.2), value: spinOffset)
                        }
                        .padding(.horizontal, 20)
                        
                        // 距离显示卡片
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "ruler")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                                Text(localized: .distance)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            ViewThatFits(in: .horizontal) {
                                // 方案一：同一行显示（数字 + 单位）
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("\(Int(distance))")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .layoutPriority(2)
                                        .animation(.easeInOut(duration: 0.3), value: distance)

                                    Text(localized: .meters)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1) // 保证单位整体，不出现局部换行
                                        .fixedSize(horizontal: true, vertical: false)

                                    Spacer(minLength: 0)
                                }

                                // 方案二：不够放时，整个单位换到下一行
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(Int(distance))")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .layoutPriority(2)
                                        .animation(.easeInOut(duration: 0.3), value: distance)

                                    Text(localized: .meters)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        
                        // 底部地址图标切换
                        destinationIconSwitcher
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                        
                        // 底部间距
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                // 打赏按钮
                Button(action: { showDonation = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text(localized: .donate)
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: { showSettings = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text(localized: .settings)
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
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
        .onAppear {
            loadAddresses()
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                startLocationUpdates()
            }
        }
        .onChange(of: showSettings) { newValue in
            // 当从设置页返回时，刷新地址与方向
            if newValue == false {
                loadAddresses()
                updateDirection()
            }
        }
        // 实时位置变化时，刷新距离与方向（使用发布者，避免 Equatable 限制）
        .onReceive(locationManager.$currentLocation) { _ in
            updateDirection()
        }
        .onChange(of: selectedDestination) {
            updateDirection()
        }
        .onChange(of: locationManager.currentHeading) {
            // 设备朝向变化时，更新箭头显示角度（按最短角度差累积）
            updateArrowRotation()
        }
        .sheet(isPresented: $showDonation) {
            DonationView(isPresented: $showDonation)
        }
        // 点击未设置的地点时弹出提示，用户可选择前往设置
        .alert(String(localized: .locationNotSetTitle), isPresented: $showSetupPrompt) {
            Button(String(localized: .cancel), role: .cancel) {}
            Button(String(localized: .setupNow)) {
                showSettings = true
            }
        } message: {
            Text(String(localized: .locationNotSetMessage))
        }
    }
    
    private func loadAddresses() {
        var loadedAddresses: [String] = []
        var loadedCoordinates: [CLLocationCoordinate2D] = []
        
        if let addr1 = UserDefaults.standard.string(forKey: UDKeys.address1), !addr1.isEmpty {
            loadedAddresses.append(addr1)
            geocodeAndStoreAddress(addr1, index: loadedCoordinates.count)
            loadedCoordinates.append(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // 占位符
        }
        if let addr2 = UserDefaults.standard.string(forKey: UDKeys.address2), !addr2.isEmpty {
            loadedAddresses.append(addr2)
            geocodeAndStoreAddress(addr2, index: loadedCoordinates.count)
            loadedCoordinates.append(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // 占位符
        }
        if let addr3 = UserDefaults.standard.string(forKey: UDKeys.address3), !addr3.isEmpty {
            loadedAddresses.append(addr3)
            geocodeAndStoreAddress(addr3, index: loadedCoordinates.count)
            loadedCoordinates.append(CLLocationCoordinate2D(latitude: 0, longitude: 0)) // 占位符
        }
        
        addresses = loadedAddresses
        destinationCoordinates = loadedCoordinates
    }
    
    private func geocodeAndStoreAddress(_ address: String, index: Int) {
        geocodingService.geocodeAddress(address) { coordinate in
            guard let coordinate = coordinate else { return }
            
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
            let nagoyaCenter = Coordinates.nagoyaCenter
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
            currentCoord = Coordinates.nagoyaStation
        }
        
        // 计算距离（米）
        let calculatedDistance = geocodingService.calculateDistance(from: currentCoord, to: destination)
        distance = calculatedDistance
        
        // 计算方向角（度）
        let calculatedBearing = geocodingService.calculateBearing(from: currentCoord, to: destination)
        
        // 箭头应该指向目标的绝对地理方向
        angle = calculatedBearing
        // 更新箭头显示角度（最短角度差累计），防止自然转动时整圈旋转
        updateArrowRotation()
    }

    // MARK: - Arrow rotation helpers
    private func wrapDelta(_ delta: Double) -> Double {
        // 归一化到 [-180, 180]
        var d = delta.truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
    
    private func updateArrowRotation() {
        // 目标相对角 = 目标方位 - 设备朝向
        let target = angle - locationManager.currentHeading
        // 与当前显示角度的最短差值
        let diff = wrapDelta(target - arrowRotation)
        // 采用最短路径更新显示角度（避免跨 0° 时出现整圈旋转）
        arrowRotation += diff
    }

    // MARK: - Slot helpers and UI
    private func slotAddress(_ slot: Int) -> String {
        switch slot {
        case 0:
            return UserDefaults.standard.string(forKey: UDKeys.address1) ?? ""
        case 1:
            return UserDefaults.standard.string(forKey: UDKeys.address2) ?? ""
        default:
            return UserDefaults.standard.string(forKey: UDKeys.address3) ?? ""
        }
    }

    private func slotIconName(_ slot: Int) -> String {
        switch slot {
        case 0: return "house.fill"
        case 1: return "building.2.fill"
        default: return "heart.fill"
        }
    }

    private func slotGradient(_ slot: Int) -> LinearGradient {
        switch slot {
        case 0:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func selectSlot(_ slot: Int) {
        let addr = slotAddress(slot)
        guard !addr.isEmpty else {
            // 未设置时，弹出提示是否前往设置页
            showSetupPrompt = true
            return
        }
        if let idx = addresses.firstIndex(of: addr) {
            selectedDestination = idx
            updateDirection()
        }
    }

    private var destinationIconSwitcher: some View {
        let slots = [0, 1, 2]
        return HStack(spacing: 28) {
            ForEach(slots, id: \.self) { slot in
                let addr = slotAddress(slot)
                let isAvailable = !addr.isEmpty
                let isSelected = isAvailable && selectedDestination < addresses.count && addresses[selectedDestination] == addr
                Button(action: { selectSlot(slot) }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(slotGradient(slot))
                                .opacity(isAvailable ? 1.0 : 0.25)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(lineWidth: isSelected ? 4 : 0)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .green],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(
                                    color: (isSelected ? Color.green : Color.black).opacity(isAvailable ? 0.18 : 0.0),
                                    radius: isSelected ? 10 : 8,
                                    x: 0, y: 4
                                )
                            Image(systemName: slotIconName(slot))
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .semibold))
                                .opacity(isAvailable ? 1.0 : 0.5)
                        }
                        Text(slot == 0 ? String(localized: .home) : slot == 1 ? String(localized: .work) : String(localized: .other))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isAvailable ? Color(UIColor.label) : Color(UIColor.tertiaryLabel))
                            .frame(width: 60)
                            .minimumScaleFactor(0.9)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
}

// 复用的指南针箭头组件：优先使用自定义图片资源，否则回退到 SF Symbols
struct CompassArrow: View {
    let rotation: Double // 传入 angle - currentHeading
    
    private func customArrowImage() -> UIImage? {
        // 支持多种命名，任意一个存在即使用
        let candidates = [
            "CompassArrowBlue",
            "compass_arrow_blue",
            "compass_arrow",
            "navigation_arrow_blue"
        ]
        for name in candidates {
            if let img = UIImage(named: name) { return img }
        }
        return nil
    }
    
    var body: some View {
        Group {
            if let uiImage = customArrowImage() {
                // 自定义图片（建议图片默认朝向为 45° NE）
                Image(uiImage: uiImage)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 84, height: 84)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                    .rotationEffect(.degrees(rotation - 45))
            } else {
                // 回退到 SF Symbol: location.fill（默认 45° NE）
                ZStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundColor(.black.opacity(0.12))
                        .offset(x: 2, y: 2)
                        .rotationEffect(.degrees(rotation - 45))
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.6, blue: 1.0), Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(rotation - 45))
                        .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 2)
                }
            }
        }
        .accessibilityLabel(Text("Compass Arrow"))
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentHeading: CLLocationDirection = 0
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10米的距离过滤
        
        // 启用磁力计方向检测
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 1 // 降低过滤值以获得更精确的方向
            locationManager.headingOrientation = .portrait
        }
        
        // 立即请求权限
        authorizationStatus = locationManager.authorizationStatus
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
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
    
    func startHeadingUpdates() {
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopHeadingUpdates() {
        locationManager.stopUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationUpdateHandler?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            startHeadingUpdates()
        case .denied, .restricted:
            print("位置权限被拒绝")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // 检查方向准确度，小于0表示无效
        if newHeading.headingAccuracy < 0 { 
            print("方向数据无效：准确度 = \(newHeading.headingAccuracy)")
            return 
        }
        
        // 优先使用真北方向，如果不可用则使用磁北方向
        let heading: CLLocationDirection
        if newHeading.trueHeading >= 0 {
            heading = newHeading.trueHeading
            print("使用真北方向：\(heading)°")
        } else {
            heading = newHeading.magneticHeading
            print("使用磁北方向：\(heading)°")
        }
        
        DispatchQueue.main.async {
            self.currentHeading = heading
        }
    }
}

struct CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView(showSettings: .constant(false))
    }
}