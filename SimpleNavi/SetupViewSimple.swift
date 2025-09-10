import SwiftUI
import CoreLocation

struct SetupViewSimple: View {
    @Binding var isFirstLaunch: Bool
    @Binding var showSettings: Bool
    
    @AppStorage(UDKeys.address1) private var address1 = ""
    @AppStorage(UDKeys.address2) private var address2 = ""
    @AppStorage(UDKeys.address3) private var address3 = ""
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
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView(isPresented: $showLanguageSelection)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                addressInputSection
                actionButtonsSection
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
                Button(action: { showLanguageSelection = true }) {
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
                    .foregroundColor(.blue)
                }
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
    }
    
    // 旧的简化输入样式已移除，改为统一使用 ModernAddressInputField
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: saveAddresses) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    Text(localized: .saveSettings)
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            address1.isEmpty
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
                            color: address1.isEmpty ? .clear : .blue.opacity(0.3),
                            radius: 12, x: 0, y: 6
                        )
                )
            }
            .disabled(address1.isEmpty)
            
            if !isFirstLaunch {
                Button(action: { showSettings = false }) {
                    Text(localized: .cancel)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
        }
    }
    
    private func saveAddresses() {
        UserDefaults.standard.set(true, forKey: UDKeys.hasSetupAddresses)
        
        if isFirstLaunch {
            UserDefaults.standard.set(false, forKey: UDKeys.isFirstLaunch)
            isFirstLaunch = false
        } else {
            showSettings = false
        }
    }
}

struct SetupViewSimple_Previews: PreviewProvider {
    static var previews: some View {
        // 预览为“从主页面进入设置”的场景：显示返回按钮
        SetupViewSimple(isFirstLaunch: .constant(false), showSettings: .constant(true))
    }
}