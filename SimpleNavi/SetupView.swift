import SwiftUI
import CoreLocation
import MapKit
import UIKit
import AppIntents

func dismissKeyboard() {
    #if canImport(UIKit)
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    #endif
}

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
    private var localizationManager = LocalizationManager.shared
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(localizationManager.currentLanguage.flag)
                    .font(.system(size: 20))
                Text(localizationManager.currentLanguage.displayName)
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .foregroundColor(.blue)
    }
}

struct SetupView: View {
    @Binding var isFirstLaunch: Bool
    @Binding var showSettings: Bool
    
    private var localizationManager = LocalizationManager.shared
    @State private var showLanguageSheet = false
    
    // 使用加密存储替代明文 @AppStorage
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var address3 = ""
    @State private var label1 = ""
    @State private var label2 = ""
    @State private var label3 = ""
    @State private var isLoading = false
    @State private var skipKeyboardDismissTap = false

    init(isFirstLaunch: Binding<Bool>, showSettings: Binding<Bool>) {
        self._isFirstLaunch = isFirstLaunch
        self._showSettings = showSettings
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 更加柔和深邃的渐变背景
                ZStack {
                    Color(uiColor: .systemBackground)
                    
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.12),
                            Color.green.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Circle()
                        .fill(Color.orange.opacity(0.05))
                        .frame(width: 400, height: 400)
                        .blur(radius: 60)
                        .offset(x: -150, y: -200)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 顶部返回按钮（非首次启动才显示）
                        HStack {
                            if !isFirstLaunch {
                                Button(action: { showSettings = false }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 20, weight: .bold))
                                        Text(localized: .back)
                                            .font(.system(size: 20, weight: .bold))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
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
                        VStack(spacing: 20) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.2), radius: 15)
                            
                            VStack(spacing: 8) {
                                Text(localized: .setupTitle)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                
                                Text(localized: .setupSubtitle)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(.white.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
            
                        // 地址输入卡片
                        VStack(spacing: 20) {
                            // Siri Tip - 引导用户使用 Siri 开启导航 (2026 Apple Intelligence 最佳实践)
                            // 暂时隐藏 Siri 提示
                            // if #available(iOS 18.0, *) {
                            //     SiriTipView(intent: StartNavigationIntent())
                            //         .padding(.bottom, 8)
                            // }

                            ModernAddressInputField(
                                icon: "house.fill",
                                iconColor: .blue,
                                label: Binding(get: { label1 }, set: { label1 = $0 }),
                                labelPlaceholder: AddressLabelStore.defaultLabel(for: 1),
                                address: $address1,
                                placeholder: String(localized: .enterHomeAddress),
                                isRequired: true,
                                slot: 1,
                                onTapInside: { skipKeyboardDismissTap = true }
                            )
                            
                            ModernAddressInputField(
                                icon: "building.2.fill",
                                iconColor: .orange,
                                label: Binding(get: { label2 }, set: { label2 = $0 }),
                                labelPlaceholder: AddressLabelStore.defaultLabel(for: 2),
                                address: $address2,
                                placeholder: String(localized: .enterWorkAddress),
                                isRequired: false,
                                slot: 2,
                                onTapInside: { skipKeyboardDismissTap = true }
                            )
                            
                            ModernAddressInputField(
                                icon: "heart.fill",
                                iconColor: .pink,
                                label: Binding(get: { label3 }, set: { label3 = $0 }),
                                labelPlaceholder: AddressLabelStore.defaultLabel(for: 3),
                                address: $address3,
                                placeholder: String(localized: .enterOtherAddress),
                                isRequired: false,
                                slot: 3,
                                onTapInside: { skipKeyboardDismissTap = true }
                            )
                        }
                        .padding(.horizontal, 20)
            
                        
                        
                        // 现代化保存按钮
                        Button(action: saveAddresses) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24, weight: .bold))
                                    Text(localized: .saveSettings)
                                        .font(.system(size: 24, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(
                                        address1.isEmpty || isLoading
                                        ? AnyShapeStyle(Color.gray.opacity(0.3))
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
                                        : .blue.opacity(0.2), 
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
                .fullScreenCover(isPresented: $showLanguageSheet) {
                    LanguageSelectionView(isPresented: $showLanguageSheet)
                        .onAppear { print("[LanguageFullScreen-SetupView] presented") }
                }
            }
        }
        .onAppear {
            Task {
                // 初始加载加密地址并执行一次性迁移（如存在旧的明文 UserDefaults）
                let s1 = await SecureStorage.shared.getString(forKey: UDKeys.address1)
                let s2 = await SecureStorage.shared.getString(forKey: UDKeys.address2)
                let s3 = await SecureStorage.shared.getString(forKey: UDKeys.address3)
                
                var a1 = s1 ?? ""
                var a2 = s2 ?? ""
                var a3 = s3 ?? ""
                
                // 迁移逻辑：如果加密存储为空且 UserDefaults 有旧数据，则迁移并删除旧数据
                if a1.isEmpty, let old = UserDefaults.standard.string(forKey: UDKeys.address1), !old.isEmpty {
                    await SecureStorage.shared.setString(old, forKey: UDKeys.address1)
                    a1 = old
                    UserDefaults.standard.removeObject(forKey: UDKeys.address1)
                }
                if a2.isEmpty, let old = UserDefaults.standard.string(forKey: UDKeys.address2), !old.isEmpty {
                    await SecureStorage.shared.setString(old, forKey: UDKeys.address2)
                    a2 = old
                    UserDefaults.standard.removeObject(forKey: UDKeys.address2)
                }
                if a3.isEmpty, let old = UserDefaults.standard.string(forKey: UDKeys.address3), !old.isEmpty {
                    await SecureStorage.shared.setString(old, forKey: UDKeys.address3)
                    a3 = old
                    UserDefaults.standard.removeObject(forKey: UDKeys.address3)
                }
                
                let l1 = await AddressLabelStore.load(slot: 1)
                let l2 = await AddressLabelStore.load(slot: 2)
                let l3 = await AddressLabelStore.load(slot: 3)

                await MainActor.run {
                    address1 = a1
                    address2 = a2
                    address3 = a3
                    label1 = l1
                    label2 = l2
                    label3 = l3
                }
            }
        }
        .onChange(of: localizationManager.currentLanguage) { _ in
            Task {
                let l1 = await AddressLabelStore.load(slot: 1)
                let l2 = await AddressLabelStore.load(slot: 2)
                let l3 = await AddressLabelStore.load(slot: 3)
                await MainActor.run {
                    label1 = l1
                    label2 = l2
                    label3 = l3
                }
            }
        }
    }
    
    private func saveAddresses() {
        isLoading = true
        
        Task {
            // 持久化到加密存储
            await SecureStorage.shared.setString(address1.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UDKeys.address1)
            await SecureStorage.shared.setString(address2.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UDKeys.address2)
            await SecureStorage.shared.setString(address3.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UDKeys.address3)
            await AddressLabelStore.save(label1, slot: 1)
            await AddressLabelStore.save(label2, slot: 2)
            await AddressLabelStore.save(label3, slot: 3)
            UserDefaults.standard.set(!address1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, forKey: UDKeys.hasSetupAddresses)
            
            // 模拟一个小的延迟以展示加载动画（实际存储很快，但给用户一点反馈感）
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                isLoading = false
                isFirstLaunch = false
                showSettings = false
            }
        }
    }
}

// 现代化地址输入组件
struct ModernAddressInputField: View {
    let icon: String
    let iconColor: Color
    var label: Binding<String>? = nil
    let labelPlaceholder: String
    @Binding var address: String
    let placeholder: String
    let isRequired: Bool
    let slot: Int
    var onTapInside: (() -> Void)? = nil
    
    @State private var isFocused = false
    
    @State private var showMapConfirm = false
    @State private var confirmedAddress = ""
    @State private var confirmedCoordinate: CLLocationCoordinate2D?
    
    private let addressManager = JapaneseAddressManager.shared
    
    private var localizationManager = LocalizationManager.shared

    init(icon: String, iconColor: Color, label: Binding<String>? = nil, labelPlaceholder: String, address: Binding<String>, placeholder: String, isRequired: Bool, slot: Int, onTapInside: (() -> Void)? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.labelPlaceholder = labelPlaceholder
        self._address = address
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.slot = slot
        self.onTapInside = onTapInside
    }
    
    private var latKey: String {
        switch slot { case 1: return UDKeys.address1Lat; case 2: return UDKeys.address2Lat; default: return UDKeys.address3Lat }
    }
    private var lonKey: String {
        switch slot { case 1: return UDKeys.address1Lon; case 2: return UDKeys.address2Lon; default: return UDKeys.address3Lon }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(iconColor)
                if let label = label {
                    TextField(labelPlaceholder, text: label, onEditingChanged: { editing in
                        if editing {
                            onTapInside?()
                        }
                    })
                        .font(.system(size: 24, weight: .bold))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .foregroundColor(.primary)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            onTapInside?()
                        }
                } else {
                    Text(labelPlaceholder)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }
                if isRequired {
                    Text("*")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.red)
                }
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    // 支持多行，完整显示地址
                    if #available(iOS 16.0, *) {
                        TextField(placeholder, text: $address, axis: .vertical)
                            .font(.system(size: 20, weight: .bold))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .lineLimit(1...8)
                            .fixedSize(horizontal: false, vertical: true)
                            .onSubmit {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isFocused = false
                                }
                            }
                    } else {
                        // iOS 15 及以下回退为单行 TextField，但允许复制查看
                        TextField(placeholder, text: $address)
                            .font(.system(size: 20, weight: .bold))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isFocused = false
                                }
                            }
                    }

                    // 清空按钮
                    if !address.isEmpty {
                        Button(action: {
                            onTapInside?()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                address = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .padding(6)
                        }
                        .accessibilityLabel("Clear address")
                        .transition(.opacity.combined(with: .scale))
                    }

                    // 地图确认按钮（始终显示，便于直接从地图选择）
                    Button(action: {
                        onTapInside?()
                        showMapConfirm = true
                    }) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground).opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    isFocused
                                    ? iconColor.opacity(0.5)
                                    : (!address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.green.opacity(0.3) : Color.clear),
                                    lineWidth: 2
                                )
                        )
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = true
                    }
                    onTapInside?()
                }
                .scaleEffect(isFocused ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                // 地址状态提示（全球）：非空即认为有效
                if !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)

                        Text(localized: .addressFormatValid)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
        .sheet(isPresented: $showMapConfirm) {
            AsyncMapConfirmSheet(slot: slot, latKey: latKey, lonKey: lonKey, address: $address, showMapConfirm: $showMapConfirm, confirmedAddress: $confirmedAddress, confirmedCoordinate: $confirmedCoordinate)
        }
    }
}

// 内部私有视图，用于处理 sheet 中的异步逻辑
private struct AsyncMapConfirmSheet: View {
    let slot: Int
    let latKey: String
    let lonKey: String
    @Binding var address: String
    @Binding var showMapConfirm: Bool
    @Binding var confirmedAddress: String
    @Binding var confirmedCoordinate: CLLocationCoordinate2D?
    @State private var initialCoord: CLLocationCoordinate2D?
    @State private var hasLoadedInitial = false

    var body: some View {
        Group {
            if hasLoadedInitial {
                AddressMapConfirmView(
                    address: address,
                    initialCoordinate: initialCoord,
                    isPresented: $showMapConfirm,
                    confirmedAddress: $confirmedAddress,
                    confirmedCoordinate: $confirmedCoordinate
                )
                .onDisappear {
                    let addrCopy = address
                    let confAddr = confirmedAddress
                    let confCoord = confirmedCoordinate
                    
                    Task {
                        if !confAddr.isEmpty {
                            await MainActor.run {
                                address = confAddr
                            }
                        }
                        if let coord = confCoord {
                            await SecureStorage.shared.setString(String(coord.latitude), forKey: latKey)
                            await SecureStorage.shared.setString(String(coord.longitude), forKey: lonKey)
                        }
                        // 若地址被清空，清理坐标，防止脏数据
                        let trimmed = (confAddr.isEmpty ? addrCopy : confAddr).trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            await SecureStorage.shared.remove(forKey: latKey)
                            await SecureStorage.shared.remove(forKey: lonKey)
                        }
                    }
                }
            } else {
                ProgressView()
                    .onAppear {
                        Task {
                            let latStr = await SecureStorage.shared.getString(forKey: latKey)
                            let lonStr = await SecureStorage.shared.getString(forKey: lonKey)
                            if let latStr = latStr, let lonStr = lonStr,
                               let lat = Double(latStr), let lon = Double(lonStr) {
                                initialCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            }
                            await MainActor.run {
                                hasLoadedInitial = true
                            }
                        }
                    }
            }
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