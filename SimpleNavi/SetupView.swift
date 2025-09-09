import SwiftUI

struct SetupView: View {
    @Binding var isFirstLaunch: Bool
    @Binding var showSettings: Bool
    
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var address3 = ""
    @State private var selectedAddressIndex = 0
    @State private var isLoading = false
    @State private var showSuggestedAddresses = false
    
    private let addressLabels = ["家", "公司", "朋友家"]
    private let suggestedNagoyaAddresses = [
        "愛知県名古屋市中区栄3-15-33",
        "愛知県名古屋市東区泉",
        "愛知県名古屋市千種区今池1-6-3",
        "愛知県名古屋市昭和区御器所",
        "愛知県名古屋市天白区植田",
        "名古屋駅",
        "名古屋城",
        "熱田神宮"
    ]
    
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
                            
                            Text("简单导航设置")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("为您的重要地点设置地址，让回家变得简单")
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
                                label: "主要地址 (家)",
                                address: $address1,
                                placeholder: "请输入家庭地址",
                                isRequired: true
                            )
                            
                            ModernAddressInputField(
                                icon: "building.2.fill",
                                iconColor: .orange,
                                label: "工作地点 (可选)",
                                address: $address2,
                                placeholder: "请输入工作地址",
                                isRequired: false
                            )
                            
                            ModernAddressInputField(
                                icon: "heart.fill",
                                iconColor: .pink,
                                label: "其他地点 (可选)",
                                address: $address3,
                                placeholder: "请输入第三个地址",
                                isRequired: false
                            )
                        }
                        .padding(.horizontal, 20)
            
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
                                    Text("使用名古屋示例地址")
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
                                        Text("常用名古屋地址")
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
                                    Text("保存设置")
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
                                        ? Color.gray.opacity(0.6)
                                        : LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
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
            }
        }
        .onAppear {
            loadSavedAddresses()
        }
    }
    
    private func loadSavedAddresses() {
        address1 = UserDefaults.standard.string(forKey: "address1") ?? ""
        address2 = UserDefaults.standard.string(forKey: "address2") ?? ""
        address3 = UserDefaults.standard.string(forKey: "address3") ?? ""
    }
    
    private func saveAddresses() {
        isLoading = true
        
        UserDefaults.standard.set(address1, forKey: "address1")
        UserDefaults.standard.set(address2, forKey: "address2")
        UserDefaults.standard.set(address3, forKey: "address3")
        UserDefaults.standard.set(true, forKey: "hasSetupAddresses")
        
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
            
            TextField(placeholder, text: $address)
                .font(.system(size: 16, weight: .medium))
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
                                    : Color.clear, 
                                    lineWidth: 2
                                )
                        )
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = true
                    }
                }
                .onSubmit {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = false
                    }
                }
                .scaleEffect(isFocused ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
}

// 保留旧版本以防兼容性问题
struct AddressInputField: View {
    let label: String
    @Binding var address: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
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