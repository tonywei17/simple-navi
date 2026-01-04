import Foundation
import CoreLocation
import MapKit
import Contacts

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
    
    // 格式化日本地址（仅对日本样式进行归一化；其它国家原样返回，以避免破坏空格等格式）
    func formatJapaneseAddress(_ address: String) -> String {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isJapaneseAddress(trimmed) else {
            // 非日本地址：保留用户输入的空格/逗号等，避免影响全球地理编码
            return trimmed
        }

        var formatted = trimmed
        // 移除多余的空格（日本地址常按连续字符书写）
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
    
    // 使用 Swift 并发 (async/await) 进行地理编码
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let formattedAddress = formatJapaneseAddress(address)
        
        // 使用 withCheckedThrowingContinuation 将基于闭包的 API 转换为 async/await
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(formattedAddress) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    continuation.resume(throwing: GeocodingError.noResults)
                    return
                }
                continuation.resume(returning: location.coordinate)
            }
        }
    }
    
    // 反向地理编码（从坐标获取地址）- 全球适用
    func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) async throws -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let placemark = placemarks?.first else {
                    continuation.resume(throwing: GeocodingError.noResults)
                    return
                }

                // iOS 提供 CNPostalAddress（全球格式），优先使用
                if let postal = placemark.postalAddress {
                    let formatter = CNPostalAddressFormatter()
                    formatter.style = .mailingAddress
                    var formatted = formatter.string(from: postal)
                    // 转为单行便于展示
                    formatted = formatted.replacingOccurrences(of: "\n", with: " ")
                    formatted = formatted.replacingOccurrences(of: "  ", with: " ")
                    let trimmed = formatted.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        continuation.resume(returning: trimmed)
                        return
                    }
                }

                // 若无 CNPostalAddress 或为空：
                // JP 使用日式拼接；其他地区使用通用逗号拼接
                var result = ""
                let iso = placemark.isoCountryCode?.uppercased() ?? ""
                if iso == "JP" {
                    var parts: [String] = []
                    if let postalCode = placemark.postalCode, !postalCode.isEmpty { parts.append(postalCode) }
                    if let administrativeArea = placemark.administrativeArea { parts.append(administrativeArea) }
                    if let locality = placemark.locality { parts.append(locality) }
                    if let subLocality = placemark.subLocality { parts.append(subLocality) }
                    if let thoroughfare = placemark.thoroughfare { parts.append(thoroughfare) }
                    if let subThoroughfare = placemark.subThoroughfare { parts.append(subThoroughfare) }
                    result = parts.joined(separator: "")
                } else {
                    var parts: [String] = []
                    // 常见顺序：街道号 街道, 城市/区县, 省/州, 邮编, 国家
                    let hasStreet = (placemark.thoroughfare?.isEmpty == false)
                    let hasNumber = (placemark.subThoroughfare?.isEmpty == false)

                    if hasStreet {
                        if hasNumber {
                            parts.append("\(placemark.subThoroughfare!) \(placemark.thoroughfare!)")
                        } else {
                            parts.append(placemark.thoroughfare!)
                        }
                    } else if let name = placemark.name, !name.isEmpty {
                        parts.append(name)
                    }

                    if let locality = placemark.locality, !locality.isEmpty { parts.append(locality) }
                    if let subAdmin = placemark.subAdministrativeArea, !subAdmin.isEmpty, !parts.contains(subAdmin) { parts.append(subAdmin) }
                    if let subLocality = placemark.subLocality, !subLocality.isEmpty, !parts.contains(subLocality) { parts.append(subLocality) }
                    if let admin = placemark.administrativeArea, !admin.isEmpty { parts.append(admin) }
                    if let postal = placemark.postalCode, !postal.isEmpty { parts.append(postal) }
                    if let country = placemark.country, !country.isEmpty { parts.append(country) }
                    result = parts.filter { !$0.isEmpty }.joined(separator: ", ")
                }

                let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    continuation.resume(returning: trimmed)
                    return
                }

                // 进一步兜底
                if let name = placemark.name, !name.isEmpty {
                    let composed = [name, placemark.locality, placemark.administrativeArea, placemark.country]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                    if !composed.isEmpty {
                        continuation.resume(returning: composed)
                        return
                    }
                }
                
                continuation.resume(throwing: GeocodingError.noResults)
            }
        }
    }

}

// MARK: - Helpers
private extension MKPlacemark {
    func coordinateDistance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let a = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b)
    }
}

// Keep landmark search as a type member via extension
extension JapaneseAddressManager {
    // 搜索附近的地标 - 异步版本
    func searchNearbyLandmarks(coordinate: CLLocationCoordinate2D) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "駅 コンビニ 病院 学校"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            return response.mapItems
        } catch {
            return []
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