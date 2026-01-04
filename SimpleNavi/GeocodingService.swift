import Foundation
import CoreLocation

class GeocodingService: ObservableObject {
    private let geocoder = CLGeocoder()
    
    static let shared = GeocodingService()
    
    // 日本名古屋地区的模拟地址数据
    private let nagoyaAddresses: [String: CLLocationCoordinate2D] = [
        // 名古屋市中区栄 (繁华商业区)
        "愛知県名古屋市中区栄3-15-33": CLLocationCoordinate2D(latitude: 35.1681, longitude: 136.9062),
        "愛知県名古屋市中区栄": CLLocationCoordinate2D(latitude: 35.1681, longitude: 136.9062),
        "栄": CLLocationCoordinate2D(latitude: 35.1681, longitude: 136.9062),
        
        // 名古屋市東区 (住宅区)
        "愛知県名古屋市東区東桜1-13-3": CLLocationCoordinate2D(latitude: 35.1787, longitude: 136.9216),
        "愛知県名古屋市東区泉": CLLocationCoordinate2D(latitude: 35.1734, longitude: 136.9156),
        
        // 名古屋城附近
        "愛知県名古屋市中区本丸1-1": CLLocationCoordinate2D(latitude: 35.1856, longitude: 136.8997),
        "名古屋城": CLLocationCoordinate2D(latitude: 35.1856, longitude: 136.8997),
        
        // 名古屋站周边
        "愛知県名古屋市中村区名駅1-1-1": CLLocationCoordinate2D(latitude: 35.1706, longitude: 136.8816),
        "名古屋駅": CLLocationCoordinate2D(latitude: 35.1706, longitude: 136.8816),
        "名古屋站": CLLocationCoordinate2D(latitude: 35.1706, longitude: 136.8816),
        
        // 熱田神宮
        "愛知県名古屋市熱田区神宮1-1-1": CLLocationCoordinate2D(latitude: 35.1282, longitude: 136.9070),
        "熱田神宮": CLLocationCoordinate2D(latitude: 35.1282, longitude: 136.9070),
        
        // 用户具体地址
        "愛知県名古屋市熱田区明野町2-10": CLLocationCoordinate2D(latitude: 35.1205, longitude: 136.9025),
        "愛知県尾張旭市緑町緑丘-100-14-10": CLLocationCoordinate2D(latitude: 35.2164, longitude: 137.0350),
        
        // 住宅区域
        "愛知県名古屋市千種区今池1-6-3": CLLocationCoordinate2D(latitude: 35.1649, longitude: 136.9280),
        "愛知県名古屋市昭和区御器所": CLLocationCoordinate2D(latitude: 35.1463, longitude: 136.9342),
        "愛知県名古屋市瑞穂区瑞穂通": CLLocationCoordinate2D(latitude: 35.1311, longitude: 136.9342),
        
        // 工业区和住宅混合区
        "愛知県名古屋市港区港町1-11": CLLocationCoordinate2D(latitude: 35.1085, longitude: 136.8645),
        "愛知県名古屋市南区道徳新町": CLLocationCoordinate2D(latitude: 35.1187, longitude: 136.9123),
        
        // 天白区住宅区
        "愛知県名古屋市天白区植田": CLLocationCoordinate2D(latitude: 35.1231, longitude: 136.9742),
        
        // 简化地址（用户可能输入的）
        "名古屋": CLLocationCoordinate2D(latitude: 35.1815, longitude: 136.9066),
        "愛知県名古屋市": CLLocationCoordinate2D(latitude: 35.1815, longitude: 136.9066),
        "家": CLLocationCoordinate2D(latitude: 35.1649, longitude: 136.9280), // 默认到今池住宅区
        "うち": CLLocationCoordinate2D(latitude: 35.1649, longitude: 136.9280), // 日语的"家"
        "我的家": CLLocationCoordinate2D(latitude: 35.1649, longitude: 136.9280)
    ]
    
    // 使用 Swift 并发 (async/await) 进行地理编码
    func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        // 使用日本地址管理器进行更智能的地理编码
        do {
            return try await JapaneseAddressManager.shared.geocodeAddress(address)
        } catch {
            // 如果失败，尝试预设的名古屋地址
            return await fallbackToPresetAddresses(address)
        }
    }
    
    private func fallbackToPresetAddresses(_ address: String) async -> CLLocationCoordinate2D? {
        // 首先检查是否有预设的名古屋地址
        if let coordinate = nagoyaAddresses[address] {
            return coordinate
        }
        
        // 检查部分匹配（用于用户输入可能不完整的情况）
        for (key, coordinate) in nagoyaAddresses {
            if key.contains(address) || address.contains(key) {
                return coordinate
            }
        }
        
        // 如果都没有匹配，返回名古屋市中心作为默认位置
        return CLLocationCoordinate2D(latitude: 35.1815, longitude: 136.9066)
    }
    
    // 获取建议的名古屋地址列表（用于用户参考）
    func getSuggestedNagoyaAddresses() -> [String] {
        return [
            "愛知県名古屋市中区栄3-15-33",
            "愛知県名古屋市東区泉",
            "愛知県名古屋市千種区今池1-6-3",
            "愛知県名古屋市昭和区御器所",
            "愛知県名古屋市天白区植田",
            "名古屋駅",
            "名古屋城",
            "熱田神宮"
        ]
    }
    
    // 计算两点之间的距离（米）
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    // 计算两点之间的方位角（度）
    func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLatRad = from.latitude * .pi / 180
        let fromLonRad = from.longitude * .pi / 180
        let toLatRad = to.latitude * .pi / 180
        let toLonRad = to.longitude * .pi / 180
        
        let deltaLon = toLonRad - fromLonRad
        
        let y = sin(deltaLon) * cos(toLatRad)
        let x = cos(fromLatRad) * sin(toLatRad) - sin(fromLatRad) * cos(toLatRad) * cos(deltaLon)
        
        let bearingRad = atan2(y, x)
        let bearingDeg = bearingRad * 180 / .pi
        
        return (bearingDeg + 360).truncatingRemainder(dividingBy: 360)
    }
}