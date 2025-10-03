import SwiftUI
import CoreLocation

struct SetupViewSimple: View {
    @Binding var isFirstLaunch: Bool
    @Binding var showSettings: Bool
    
    // 使用加密存储替代明文 @AppStorage
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var address3 = ""
    @State private var showLanguageSelection = false
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    private let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    
    var body: some View {
        Group {
            if isPreview {
                NavigationView { content }
            } else {
                content
            }
        }
        .fullScreenCover(isPresented: $showLanguageSelection) {
            LanguageSelectionView(isPresented: $showLanguageSelection)
                .onAppear { print("[LanguageFullScreen] presented") }
        }
        // 自动保存：当地址1有内容时，标记已完成设置
        .onChange(of: address1) { newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            SecureStorage.shared.setString(trimmed, forKey: UDKeys.address1)
            let has = !trimmed.isEmpty
            UserDefaults.standard.set(has, forKey: UDKeys.hasSetupAddresses)
        }
        .onChange(of: address2) { newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            SecureStorage.shared.setString(trimmed, forKey: UDKeys.address2)
        }
        .onChange(of: address3) { newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            SecureStorage.shared.setString(trimmed, forKey: UDKeys.address3)
        }
        .onAppear {
            // 初始加载加密地址并执行一次性迁移（如存在旧的明文 UserDefaults）
            let s1 = SecureStorage.shared.getString(forKey: UDKeys.address1)
            let s2 = SecureStorage.shared.getString(forKey: UDKeys.address2)
            let s3 = SecureStorage.shared.getString(forKey: UDKeys.address3)
            var a1 = s1 ?? ""
            var a2 = s2 ?? ""
            var a3 = s3 ?? ""
            if a1.isEmpty, let old = UserDefaults.standard.string(forKey: UDKeys.address1), !old.isEmpty {
                SecureStorage.shared.setString(old, forKey: UDKeys.address1)
                a1 = old
                UserDefaults.standard.removeObject(forKey: UDKeys.address1)
            }
            if a2.isEmpty, let old = UserDefaults.standard.string(forKey: UDKeys.address2), !old.isEmpty {
                SecureStorage.shared.setString(old, forKey: UDKeys.address2)
                a2 = old
                UserDefaults.standard.removeObject(forKey: UDKeys.address2)
            }
            if a3.isEmpty, let old = UserDefaults.standard.string(forKey: UDKeys.address3), !old.isEmpty {
                SecureStorage.shared.setString(old, forKey: UDKeys.address3)
                a3 = old
                UserDefaults.standard.removeObject(forKey: UDKeys.address3)
            }
            address1 = a1
            address2 = a2
            address3 = a3
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                addressInputSection
            }
            .padding(.top, 12)
            .padding([.leading, .trailing, .bottom])
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.green.opacity(0.05),
                    Color.orange.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        )
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 语言选择按钮
            HStack {
                if showSettings || isPreview {
                    Button(action: { showSettings = false }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(localized: .back)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue.opacity(0.15))
                        )
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
                LanguagePickerButton(action: {
                    print("[SetupViewSimple] LanguagePicker tapped")
                    showLanguageSelection = true
                })
            }
            
            Image(systemName: "house.circle.fill")
                .font(.system(size: 52))
                .foregroundColor(.blue)
            
            Text(localized: .setupTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(localized: .setupSubtitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 8)
        )
    }
    
    private var addressInputSection: some View {
        VStack(spacing: 20) {
            ModernAddressInputField(
                icon: "house.fill",
                iconColor: .blue,
                label: String(localized: .address1Home),
                address: $address1,
                placeholder: String(localized: .enterHomeAddress),
                isRequired: true,
                slot: 1
            )
            
            ModernAddressInputField(
                icon: "building.2.fill",
                iconColor: .orange,
                label: String(localized: .address2Work),
                address: $address2,
                placeholder: String(localized: .enterWorkAddress),
                isRequired: false,
                slot: 2
            )
            
            ModernAddressInputField(
                icon: "heart.fill",
                iconColor: .pink,
                label: String(localized: .address3Other),
                address: $address3,
                placeholder: String(localized: .enterOtherAddress),
                isRequired: false,
                slot: 3
            )
        }
    }
    
    // 旧的简化输入样式已移除，改为统一使用 ModernAddressInputField
}

struct SetupViewSimple_Previews: PreviewProvider {
    static var previews: some View {
        // 预览为“从主页面进入设置”的场景：显示返回按钮
        SetupViewSimple(isFirstLaunch: .constant(false), showSettings: .constant(true))
    }
}