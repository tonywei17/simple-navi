import SwiftUI
import CoreLocation
import MapKit

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
    
    // 使用加密存储替代明文 @AppStorage
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var address3 = ""
    @State private var isLoading = false

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
                .fullScreenCover(isPresented: $showLanguageSheet) {
                    LanguageSelectionView(isPresented: $showLanguageSheet)
                        .onAppear { print("[LanguageFullScreen-SetupView] presented") }
                }
            }
        }
        .onAppear {
            // 加载加密存储中的已保存地址
            address1 = SecureStorage.shared.getString(forKey: UDKeys.address1) ?? ""
            address2 = SecureStorage.shared.getString(forKey: UDKeys.address2) ?? ""
            address3 = SecureStorage.shared.getString(forKey: UDKeys.address3) ?? ""
        }
    }
    
    private func saveAddresses() {
        isLoading = true
        // 持久化到加密存储
        SecureStorage.shared.setString(address1.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UDKeys.address1)
        SecureStorage.shared.setString(address2.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UDKeys.address2)
        SecureStorage.shared.setString(address3.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UDKeys.address3)
        UserDefaults.standard.set(!address1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, forKey: UDKeys.hasSetupAddresses)
        
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
    
    @State private var showMapConfirm = false
    @State private var confirmedAddress = ""
    @State private var confirmedCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var addressManager = JapaneseAddressManager.shared
    
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
                    // 支持多行，完整显示地址
                    if #available(iOS 16.0, *) {
                        TextField(placeholder, text: $address, axis: .vertical)
                            .font(.system(size: 16, weight: .medium))
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
                            .font(.system(size: 16, weight: .medium))
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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                address = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .padding(6)
                        }
                        .accessibilityLabel("Clear address")
                        .transition(.opacity.combined(with: .scale))
                    }

                    // 地图确认按钮（始终显示，便于直接从地图选择）
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
                                    : (!address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.green : Color.clear),
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
                
                // 地址状态提示（全球）：非空即认为有效
                if !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)

                        Text(localized: .addressFormatValid)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 4)
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
                    // 保存到加密存储（父视图通过绑定会触发 onChange）
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