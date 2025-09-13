import SwiftUI
import CoreLocation
import MapKit
import Contacts

// MARK: - 一次性定位提供者（用于为搜索建议设定当前区域）
final class OneShotLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    private let manager = CLLocationManager()
    private var started = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func start() {
        guard !started else { return }
        started = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 静默失败，不影响输入联想
    }
}

// 统一的语言选择按钮（带国旗 + 语言名）
struct LanguagePickerButton: View {
    let action: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(localizationManager.currentLanguage.flag)
                    .font(.system(size: 16))
                Text(localizationManager.currentLanguage.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .foregroundColor(.blue)
    }
}

struct SetupView: View {
    @Binding var isFirstLaunch: Bool
    @Binding var showSettings: Bool
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showLanguageSheet = false
    
    @AppStorage(UDKeys.address1) private var address1 = ""
    @AppStorage(UDKeys.address2) private var address2 = ""
    @AppStorage(UDKeys.address3) private var address3 = ""
    @State private var isLoading = false
    @State private var showSuggestedAddresses = false
    private let enableNagoyaSamples = false
    
    private var suggestedNagoyaAddresses: [String] {
        GeocodingService.shared.getSuggestedNagoyaAddresses()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 现代化渐变背景
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.green.opacity(0.05),
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 顶部返回按钮（非首次启动才显示）
                        HStack {
                            if !isFirstLaunch {
                                Button(action: { showSettings = false }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(localized: .back)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                                .foregroundColor(.blue)
                            }
                            Spacer()
                            // 语言选择按钮（首次进入或设置页均显示）
                            LanguagePickerButton(action: { showLanguageSheet = true })
                        }
                        .padding(.horizontal, 20)
                        // 顶部标题卡片
                        VStack(spacing: 16) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 10)
                            
                            Text(localized: .setupTitle)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text(localized: .setupSubtitle)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 30)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
            
                        // 地址输入卡片
                        VStack(spacing: 20) {
                            ModernAddressInputField(
                                icon: "house.fill",
                                iconColor: .blue,
                                label: String(localized: .address1Home),
                                address: $address1,
                                placeholder: String(localized: .enterHomeAddress),
                                isRequired: true
                            )
                            
                            ModernAddressInputField(
                                icon: "building.2.fill",
                                iconColor: .orange,
                                label: String(localized: .address2Work),
                                address: $address2,
                                placeholder: String(localized: .enterWorkAddress),
                                isRequired: false
                            )
                            
                            ModernAddressInputField(
                                icon: "heart.fill",
                                iconColor: .pink,
                                label: String(localized: .address3Other),
                                address: $address3,
                                placeholder: String(localized: .enterOtherAddress),
                                isRequired: false
                            )
                        }
                        .padding(.horizontal, 20)
            
                        // 名古屋示例地址（默认隐藏）
                        if enableNagoyaSamples {
                            // 名古屋地址建议卡片
                            VStack(spacing: 16) {
                                Button(action: { 
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showSuggestedAddresses.toggle()
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.system(size: 20, weight: .medium))
                                        Text(localized: .useNagoyaSamples)
                                            .font(.system(size: 18, weight: .medium))
                                        Spacer()
                                        Image(systemName: showSuggestedAddresses ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 16, weight: .medium))
                                            .rotationEffect(.degrees(showSuggestedAddresses ? 0 : 0))
                                            .animation(.easeInOut(duration: 0.2), value: showSuggestedAddresses)
                                    }
                                    .foregroundColor(.blue)
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.blue.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                
                                if showSuggestedAddresses {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(.green)
                                            Text(localized: .commonNagoyaAddresses)
                                                .font(.system(size: 18, weight: .semibold))
                                            Spacer()
                                        }
                                        
                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                            ForEach(suggestedNagoyaAddresses, id: \.self) { address in
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        if address1.isEmpty {
                                                            address1 = address
                                                        } else if address2.isEmpty {
                                                            address2 = address
                                                        } else if address3.isEmpty {
                                                            address3 = address
                                                        }
                                                        showSuggestedAddresses = false
                                                    }
                                                }) {
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Text(address)
                                                            .font(.system(size: 14, weight: .medium))
                                                            .multilineTextAlignment(.leading)
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                            .lineLimit(2)
                                                    }
                                                    .padding(12)
                                                    .frame(maxWidth: .infinity, minHeight: 60)
                                                    .background(Color.white)
                                                    .cornerRadius(12)
                                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                                }
                                                .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemBackground))
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 现代化保存按钮
                        Button(action: saveAddresses) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                    Text(localized: .saveSettings)
                                        .font(.system(size: 20, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        address1.isEmpty || isLoading
                                        ? AnyShapeStyle(Color.gray.opacity(0.6))
                                        : AnyShapeStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    )
                                    .shadow(
                                        color: address1.isEmpty || isLoading 
                                        ? .clear 
                                        : .blue.opacity(0.3), 
                                        radius: 12, x: 0, y: 6
                                    )
                            )
                            .scaleEffect(address1.isEmpty || isLoading ? 0.98 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: address1.isEmpty)
                            .animation(.easeInOut(duration: 0.2), value: isLoading)
                        }
                        .disabled(address1.isEmpty || isLoading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                        // 底部间距
                        Color.clear
                            .frame(height: 30)
                    }
                }
                .sheet(isPresented: $showLanguageSheet) {
                    LanguageSelectionView(isPresented: $showLanguageSheet)
                }
            }
        }
    }
    
    private func saveAddresses() {
        isLoading = true
        
        UserDefaults.standard.set(true, forKey: UDKeys.hasSetupAddresses)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            isFirstLaunch = false
            showSettings = false
        }
    }
}

// 现代化地址输入组件
struct ModernAddressInputField: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var address: String
    let placeholder: String
    let isRequired: Bool
    
    @State private var isFocused = false
    @State private var suggestions: [String] = []
    @State private var showSuggestions = false
    @State private var showMapConfirm = false
    @State private var confirmedAddress = ""
    @State private var confirmedCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var addressManager = JapaneseAddressManager.shared
    @StateObject private var searchCompleter = AddressSearchCompleter()
    @StateObject private var locationProvider = OneShotLocationProvider()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                if isRequired {
                    Text("*")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                }
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField(placeholder, text: $address)
                        .font(.system(size: 16, weight: .medium))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: address) { newValue in
                            updateSuggestions(for: newValue)
                        }
                        .onSubmit {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isFocused = false
                                showSuggestions = false
                            }
                        }
                    
                    // 地图确认按钮
                    if !address.isEmpty {
                        Button(action: {
                            showMapConfirm = true
                        }) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isFocused 
                                    ? iconColor 
                                    : (addressManager.isJapaneseAddress(address) ? Color.green : Color.clear), 
                                    lineWidth: 2
                                )
                        )
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = true
                    }
                }
                .scaleEffect(isFocused ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                // 地址格式提示
                if !address.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: addressManager.isJapaneseAddress(address) ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(addressManager.isJapaneseAddress(address) ? .green : .orange)
                        
                        Text(localized: addressManager.isJapaneseAddress(address) ? .addressFormatValid : .addressFormatSuggestion)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // 智能地址建议
                if showSuggestions && !suggestions.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text(localized: .addressSuggestions)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(String(localized: .hide)) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSuggestions = false
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        
                        LazyVStack(spacing: 6) {
                            ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        address = suggestion
                                        showSuggestions = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "mappin")
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                        Text(suggestion)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .font(.system(size: 10))
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemGray6))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
        .sheet(isPresented: $showMapConfirm) {
            AddressMapConfirmView(
                address: address,
                isPresented: $showMapConfirm,
                confirmedAddress: $confirmedAddress,
                confirmedCoordinate: $confirmedCoordinate
            )
            .onDisappear {
                if !confirmedAddress.isEmpty {
                    address = confirmedAddress
                }
            }
        }
        .onReceive(searchCompleter.$suggestions) { new in
            suggestions = new
            withAnimation(.easeInOut(duration: 0.2)) {
                showSuggestions = !new.isEmpty
            }
        }
        .onAppear {
            // 获取一次性定位以便按用户位置收敛搜索建议
            locationProvider.start()
        }
    }
    
    private func updateSuggestions(for input: String) {
        guard !input.isEmpty else {
            showSuggestions = false
            suggestions = []
            return
        }
        // 使用 MapKit 自动补全，结合当前位置（如可用）限定区域
        // 目标语言对应的 Locale
        let locale: Locale
        switch localizationManager.currentLanguage {
        case .japanese: locale = Locale(identifier: "ja_JP")
        case .chinese:  locale = Locale(identifier: "zh_Hans_CN")
        case .english:  locale = Locale(identifier: "en_US")
        }

        if let coord = locationProvider.coordinate {
            let region = MKCoordinateRegion(
                center: coord,
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
            searchCompleter.update(query: input, region: region, locale: locale)
        } else {
            searchCompleter.update(query: input, region: nil, locale: locale)
        }
    }
}

// MARK: - MapKit 搜索补全封装
final class AddressSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [String] = []
    private let completer: MKLocalSearchCompleter
    private var targetLocale: Locale = .current
    private var lastRegion: MKCoordinateRegion?
    
    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        if #available(iOS 13.0, *) {
            self.completer.resultTypes = [.address, .pointOfInterest]
        }
    }
    
    func update(query: String, region: MKCoordinateRegion? = nil, locale: Locale? = nil) {
        if let locale = locale { self.targetLocale = locale }
        self.lastRegion = region
        if let region = region { completer.region = region }
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let top = Array(completer.results.prefix(3))
        // 先用原始标题+副标题立即显示
        var base = top.map { c in
            c.subtitle.isEmpty ? c.title : "\(c.title) \(c.subtitle)"
        }
        DispatchQueue.main.async { [base] in
            self.suggestions = base
        }
        
        // 再用 MKLocalSearch 拿到 placemark.postalAddress 并按语言格式化后逐个替换
        for (idx, completion) in top.enumerated() {
            let request = MKLocalSearch.Request(completion: completion)
            if let r = lastRegion { request.region = r }
            let search = MKLocalSearch(request: request)
            search.start { response, _ in
                guard let item = response?.mapItems.first else { return }
                let coord = item.placemark.coordinate
                let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location, preferredLocale: self.targetLocale) { placemarks, _ in
                    if let p = placemarks?.first {
                        // 优先使用 CLPlacemark 的 postalAddress（按目标语言生成）
                        if let postal = p.postalAddress {
                            let f = CNPostalAddressFormatter()
                            f.style = .mailingAddress
                            var text = f.string(from: postal).replacingOccurrences(of: "\n", with: " ")
                            DispatchQueue.main.async { if idx < self.suggestions.count { self.suggestions[idx] = text } }
                            return
                        }
                        // 退化：手工组装（尽可能使用目标语言的字段）
                        var parts: [String] = []
                        if let code = p.postalCode { parts.append(code) }
                        if let admin = p.administrativeArea { parts.append(admin) }
                        if let locality = p.locality { parts.append(locality) }
                        if let sub = p.subLocality { parts.append(sub) }
                        if let thoroughfare = p.thoroughfare { parts.append(thoroughfare) }
                        if let subThoroughfare = p.subThoroughfare { parts.append(subThoroughfare) }
                        let text = parts.joined(separator: " ")
                        DispatchQueue.main.async { if idx < self.suggestions.count { self.suggestions[idx] = text } }
                    } else if let postal = item.placemark.postalAddress {
                        // 无 geocode 结果时，格式化 placemark 自带的 postalAddress
                        let f = CNPostalAddressFormatter()
                        f.style = .mailingAddress
                        let text = f.string(from: postal).replacingOccurrences(of: "\n", with: " ")
                        DispatchQueue.main.async { if idx < self.suggestions.count { self.suggestions[idx] = text } }
                    }
                }
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.suggestions = []
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(
            isFirstLaunch: .constant(true),
            showSettings: .constant(false)
        )
    }
}