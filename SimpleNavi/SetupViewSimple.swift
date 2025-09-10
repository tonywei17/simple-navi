import SwiftUI
import CoreLocation

struct SetupViewSimple: View {
    @Binding var isFirstLaunch: Bool
    @Binding var showSettings: Bool
    
    @AppStorage(UDKeys.address1) private var address1 = ""
    @AppStorage(UDKeys.address2) private var address2 = ""
    @AppStorage(UDKeys.address3) private var address3 = ""
    @State private var showMapConfirmation = false
    @State private var currentAddressForMap = ""
    @State private var currentAddressIndex = 0
    @State private var confirmedAddress = ""
    @State private var confirmedCoordinate: CLLocationCoordinate2D? = nil
    @State private var showLanguageSelection = false
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    addressInputSection
                    actionButtonsSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showMapConfirmation) {
            AddressMapConfirmView(
                address: currentAddressForMap,
                isPresented: $showMapConfirmation,
                confirmedAddress: $confirmedAddress,
                confirmedCoordinate: $confirmedCoordinate
            )
        }
        .onChange(of: showMapConfirmation) { newValue in
            // 当地图确认界面关闭时，更新相应的地址
            if !newValue && !confirmedAddress.isEmpty {
                switch currentAddressIndex {
                case 0: address1 = confirmedAddress
                case 1: address2 = confirmedAddress
                case 2: address3 = confirmedAddress
                default: break
                }
                confirmedAddress = ""
                confirmedCoordinate = nil
            }
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView(isPresented: $showLanguageSelection)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 语言选择按钮
            HStack {
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
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text(localized: .setupTitle)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text(localized: .setupSubtitle)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
        )
    }
    
    private var addressInputSection: some View {
        VStack(spacing: 16) {
            addressInputField(
                title: String(localized: .address1Home),
                address: $address1,
                placeholder: String(localized: .enterHomeAddress),
                index: 0
            )
            
            addressInputField(
                title: String(localized: .address2Work),
                address: $address2,
                placeholder: String(localized: .enterWorkAddress),
                index: 1
            )
            
            addressInputField(
                title: String(localized: .address3Other),
                address: $address3,
                placeholder: String(localized: .enterOtherAddress),
                index: 2
            )
        }
    }
    
    private func addressInputField(title: String, address: Binding<String>, placeholder: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField(placeholder, text: address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 16))
            
            // 地图确认按钮
            if !address.wrappedValue.isEmpty {
                Button(action: {
                    currentAddressForMap = address.wrappedValue
                    currentAddressIndex = index
                    showMapConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "map")
                            .font(.system(size: 16))
                        Text(localized: .confirmOnMap)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 5)
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: saveAddresses) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text(localized: .saveSettings)
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
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
        SetupViewSimple(isFirstLaunch: .constant(true), showSettings: .constant(true))
    }
}