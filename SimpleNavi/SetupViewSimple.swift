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
        // 自动保存：当地址1有内容时，标记已完成设置
        .onChange(of: address1) { newValue in
            let has = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            UserDefaults.standard.set(has, forKey: UDKeys.hasSetupAddresses)
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
                LanguagePickerButton(action: { showLanguageSelection = true })
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
}

struct SetupViewSimple_Previews: PreviewProvider {
    static var previews: some View {
        // 预览为“从主页面进入设置”的场景：显示返回按钮
        SetupViewSimple(isFirstLaunch: .constant(false), showSettings: .constant(true))
    }
}