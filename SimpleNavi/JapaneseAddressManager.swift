import Foundation
import CoreLocation
import MapKit

// 日本地址管理器
class JapaneseAddressManager: ObservableObject {
    static let shared = JapaneseAddressManager()
    
    // 日本地址格式模式
    private let japaneseAddressPatterns = [
        // 完整格式: 都道府県 + 市区町村 + 丁目・番地・号
        #"^(.+?[都道府県])(.+?[市区町村])(.+)$"#,
        // 简化格式: 市区町村 + 丁目・番地
        #"^(.+?[市区町村])(.+)$"#,
        // 名古屋特定格式
        #"^(愛知県)?(名古屋市)?(.+区)(.+)$"#
    ]
    
    // 日语地址关键词
    private let japaneseLocationKeywords = [
        // 都道府県
        "都", "道", "府", "県",
        // 市区町村
        "市", "区", "町", "村",
        // 丁目・番地・号
        "丁目", "番地", "号", "番",
        // 建物类型
        "マンション", "アパート", "ハイツ", "コーポ", "ビル",
        // 方向
        "東", "西", "南", "北", "中央",
        // 数字
        "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"
    ]
    
    // 日本主要城市和地区
    private let majorJapaneseCities = [
        "東京": ["渋谷区", "新宿区", "港区", "千代田区", "中央区", "品川区"],
        "大阪": ["大阪市", "堺市", "豊中市", "吹田市", "高槻市"],
        "名古屋": ["中区", "東区", "西区", "南区", "北区", "中村区", "中川区", "港区", "守山区", "緑区", "名東区", "天白区", "熱田区", "昭和区", "瑞穂区", "千種区"],
        "横浜": ["横浜市", "川崎市", "藤沢市", "茅ヶ崎市"],
        "福岡": ["福岡市", "北九州市", "久留米市"],
        "京都": ["京都市", "宇治市", "亀岡市"],
        "神戸": ["神戸市", "尼崎市", "西宮市"]
    ]
    
    // 验证是否为日本地址
    func isJapaneseAddress(_ address: String) -> Bool {
        return japaneseLocationKeywords.contains { keyword in
            address.contains(keyword)
        }
    }
    
    // 格式化日本地址
    func formatJapaneseAddress(_ address: String) -> String {
        var formatted = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除多余的空格
        formatted = formatted.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        
        // 标准化常见的地址缩写
        let abbreviations = [
            "愛知県名古屋市": "愛知県名古屋市",
            "名古屋": "愛知県名古屋市",
            "栄": "愛知県名古屋市中区栄",
            "名駅": "愛知県名古屋市中村区名駅"
        ]
        
        for (key, value) in abbreviations {
            if formatted.hasPrefix(key) && formatted != value {
                formatted = formatted.replacingOccurrences(of: key, with: value)
            }
        }
        
        return formatted
    }
    
    // 获取地址建议
    func getAddressSuggestions(for input: String) -> [String] {
        _ = input.lowercased()
        var suggestions: [String] = []
        
        // 基于输入提供智能建议
        if input.contains("名古屋") || input.contains("なごや") {
            suggestions.append(contentsOf: [
                "愛知県名古屋市中区栄3-15-33",
                "愛知県名古屋市東区泉1-23-22",
                "愛知県名古屋市千種区今池1-6-3",
                "愛知県名古屋市昭和区御器所通3-12-1",
                "愛知県名古屋市中村区名駅1-1-1"
            ])
        }
        
        if input.contains("栄") || input.contains("さかえ") {
            suggestions.append(contentsOf: [
                "愛知県名古屋市中区栄3-15-33",
                "愛知県名古屋市中区栄2-10-19",
                "愛知県名古屋市中区栄4-1-8"
            ])
        }
        
        if input.contains("駅") || input.contains("えき") {
            suggestions.append(contentsOf: [
                "愛知県名古屋市中村区名駅1-1-1",
                "愛知県名古屋市千種区今池駅前",
                "愛知県名古屋市東区新栄町駅前"
            ])
        }
        
        return suggestions.prefix(5).map { $0 }
    }
    
    // 使用Apple的地理编码服务
    func geocodeAddress(_ address: String, completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        let geocoder = CLGeocoder()
        let formattedAddress = formatJapaneseAddress(address)
        
        // 设置日本地区的地理编码
        geocoder.geocodeAddressString(formattedAddress) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    completion(.failure(GeocodingError.noResults))
                    return
                }
                
                completion(.success(location.coordinate))
            }
        }
    }
    
    // 反向地理编码（从坐标获取地址）
    func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D, completion: @escaping (Result<String, Error>) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    completion(.failure(GeocodingError.noResults))
                    return
                }
                
                // 构建日本格式的地址
                var addressComponents: [String] = []
                
                if let country = placemark.country, country == "日本" {
                    if let administrativeArea = placemark.administrativeArea {
                        addressComponents.append(administrativeArea)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    if let subLocality = placemark.subLocality {
                        addressComponents.append(subLocality)
                    }
                    if let thoroughfare = placemark.thoroughfare {
                        addressComponents.append(thoroughfare)
                    }
                    if let subThoroughfare = placemark.subThoroughfare {
                        addressComponents.append(subThoroughfare)
                    }
                }
                
                let address = addressComponents.joined(separator: "")
                completion(.success(address.isEmpty ? "住所不明" : address))
            }
        }
    }
    
    // 搜索附近的地标
    func searchNearbyLandmarks(coordinate: CLLocationCoordinate2D, completion: @escaping ([MKMapItem]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "駅 コンビニ 病院 学校"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                completion(response?.mapItems ?? [])
            }
        }
    }
}

// 地理编码错误类型
enum GeocodingError: LocalizedError {
    case noResults
    case invalidAddress
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noResults:
            return "住所が見つかりませんでした"
        case .invalidAddress:
            return "無効な住所です"
        case .networkError:
            return "ネットワークエラーが発生しました"
        }
    }
}