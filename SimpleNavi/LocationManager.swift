import Foundation
import CoreLocation
import UIKit

@MainActor
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
            // 细粒度角度步进（1°）即可满足指向需求，同时显著降低回调频率
            locationManager.headingFilter = 1
            updateHeadingOrientation() // 根据设备方向设置合适的 headingOrientation
        }
        
        // 立即请求权限
        authorizationStatus = locationManager.authorizationStatus
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        // 监听设备方向变化，动态调整 headingOrientation（面朝上时使用 .faceUp 更接近系统指南针）
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
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

    // 允许外部根据场景调整角度步进
    func setHeadingFilter(_ degrees: CLLocationDegrees) {
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = degrees
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            locationUpdateHandler?(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
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
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // 检查方向准确度，小于0表示无效
        if newHeading.headingAccuracy < 0 { 
            print("方向数据无效：准确度 = \(newHeading.headingAccuracy)")
            return 
        }
        
        // 优先使用真北；若不可用则回落到磁北（系统指南针在定位未就绪前也会短暂使用磁北）。
        let heading: CLLocationDirection
        if newHeading.trueHeading >= 0 {
            heading = newHeading.trueHeading
        } else {
            heading = newHeading.magneticHeading
        }
        
        Task { @MainActor in
            self.currentHeading = heading
        }
    }

    // 当系统认为需要时，显示校准界面（与系统指南针保持一致的流程）
    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }

    // MARK: - Heading orientation helpers
    @objc private func handleOrientationChange() {
        updateHeadingOrientation()
    }

    private func updateHeadingOrientation() {
        // 与系统指南针接近的策略：
        // - 平放时使用 .faceUp（系统指南针常用姿态）
        // - 其他姿态使用 .portrait，避免横屏/倒置带来的象限偏移
        let dev = UIDevice.current.orientation
        let cl: CLDeviceOrientation = (dev == .faceUp || dev == .faceDown) ? .faceUp : .portrait
        if CLLocationManager.headingAvailable() {
            locationManager.headingOrientation = cl
        }
    }
}
