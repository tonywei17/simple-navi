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
        VStack(spacing: 30) {
            Text("简单导航设置")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Text("请输入最多3个重要地址")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                AddressInputField(
                    label: "地址1 (家)",
                    address: $address1,
                    placeholder: "请输入家庭地址"
                )
                
                AddressInputField(
                    label: "地址2 (可选)",
                    address: $address2,
                    placeholder: "请输入第二个地址"
                )
                
                AddressInputField(
                    label: "地址3 (可选)",
                    address: $address3,
                    placeholder: "请输入第三个地址"
                )
            }
            .padding(.horizontal, 20)
            
            // 名古屋地址建议按钮
            Button("使用名古屋示例地址") {
                showSuggestedAddresses.toggle()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            
            if showSuggestedAddresses {
                VStack(alignment: .leading, spacing: 8) {
                    Text("名古屋地区常用地址：")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(suggestedNagoyaAddresses, id: \.self) { address in
                            Button(action: {
                                if address1.isEmpty {
                                    address1 = address
                                } else if address2.isEmpty {
                                    address2 = address
                                } else if address3.isEmpty {
                                    address3 = address
                                }
                                showSuggestedAddresses = false
                            }) {
                                Text(address)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 20)
            }
            
            Button(action: saveAddresses) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("保存设置")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(address1.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .disabled(address1.isEmpty || isLoading)
            
            Spacer()
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