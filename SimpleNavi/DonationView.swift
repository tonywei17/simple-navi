import SwiftUI
import StoreKit

// 打赏选项数据结构
struct DonationOption {
    let id: String
    let titleKey: LocalizedStringKey
    let descriptionKey: LocalizedStringKey
    let price: String
    let localizedPrice: String
    let icon: String
    let gradient: LinearGradient
}

struct DonationView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isProcessingPurchase = false
    @State private var showThankYou = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 根据当前语言设置货币和价格
    private var donationOptions: [DonationOption] {
        switch localizationManager.currentLanguage {
        case .chinese:
            return [
                DonationOption(
                    id: "coffee_regular_cn",
                    titleKey: .coffeeRegular,
                    descriptionKey: .coffeeRegularDesc,
                    price: "¥15",
                    localizedPrice: "¥15",
                    icon: "cup.and.saucer",
                    gradient: LinearGradient(colors: [.brown, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                ),
                DonationOption(
                    id: "coffee_latte_cn", 
                    titleKey: .coffeeLatte,
                    descriptionKey: .coffeeLatteDesc,
                    price: "¥35",
                    localizedPrice: "¥35",
                    icon: "cup.and.saucer.fill",
                    gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                ),
                DonationOption(
                    id: "afternoon_tea_cn",
                    titleKey: .afternoonTea,
                    descriptionKey: .afternoonTeaDesc,
                    price: "¥68",
                    localizedPrice: "¥68",
                    icon: "leaf.fill",
                    gradient: LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            ]
        case .japanese:
            return [
                DonationOption(
                    id: "coffee_regular_jp",
                    titleKey: .coffeeRegular,
                    descriptionKey: .coffeeRegularDesc,
                    price: "¥300",
                    localizedPrice: "¥300",
                    icon: "cup.and.saucer",
                    gradient: LinearGradient(colors: [.brown, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                ),
                DonationOption(
                    id: "coffee_latte_jp",
                    titleKey: .coffeeLatte,
                    descriptionKey: .coffeeLatteDesc,
                    price: "¥750",
                    localizedPrice: "¥750",
                    icon: "cup.and.saucer.fill",
                    gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                ),
                DonationOption(
                    id: "afternoon_tea_jp",
                    titleKey: .afternoonTea,
                    descriptionKey: .afternoonTeaDesc,
                    price: "¥1500",
                    localizedPrice: "¥1500",
                    icon: "leaf.fill",
                    gradient: LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            ]
        case .english:
            return [
                DonationOption(
                    id: "coffee_regular_us",
                    titleKey: .coffeeRegular,
                    descriptionKey: .coffeeRegularDesc,
                    price: "$1.99",
                    localizedPrice: "$1.99",
                    icon: "cup.and.saucer",
                    gradient: LinearGradient(colors: [.brown, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                ),
                DonationOption(
                    id: "coffee_latte_us",
                    titleKey: .coffeeLatte,
                    descriptionKey: .coffeeLatteDesc,
                    price: "$4.99",
                    localizedPrice: "$4.99", 
                    icon: "cup.and.saucer.fill",
                    gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                ),
                DonationOption(
                    id: "afternoon_tea_us",
                    titleKey: .afternoonTea,
                    descriptionKey: .afternoonTeaDesc,
                    price: "$9.99",
                    localizedPrice: "$9.99",
                    icon: "leaf.fill",
                    gradient: LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationBarHidden(true)
        }
        .alert(String(localized: .thankYou), isPresented: $showThankYou) {
            Button(String(localized: .done)) {
                isPresented = false
            }
        } message: {
            Text(String(localized: .purchaseComplete))
        }
        .alert(String(localized: .error), isPresented: $showError) {
            Button(String(localized: .done)) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var mainContent: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        donationOptionsSection
                        cancelButton
                    }
                }
                
                if isProcessingPurchase {
                    loadingOverlay
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.orange.opacity(0.1),
                Color.red.opacity(0.05),
                Color.pink.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            heartIcon
            
            Text(String(localized: .supportDeveloper))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(String(localized: .donateMessage))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    private var heartIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: .orange.opacity(0.3), radius: 15, x: 0, y: 8)
            
            Image(systemName: "heart.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var donationOptionsSection: some View {
        VStack(spacing: 16) {
            ForEach(donationOptions, id: \.id) { option in
                donationOptionCard(option: option)
            }
            
            customAmountCard()
        }
        .padding(.horizontal, 20)
    }
    
    private var cancelButton: some View {
        Button(action: {
            isPresented = false
        }) {
            Text(String(localized: .cancel))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text(String(localized: .loading))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                )
            )
    }
    
    // 打赏选项卡片
    @ViewBuilder
    private func donationOptionCard(option: DonationOption) -> some View {
        Button(action: {
            processDonation(option: option)
        }) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(option.gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // 文本信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: option.titleKey))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(String(localized: option.descriptionKey))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 价格
                Text(option.localizedPrice)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
            )
            .scaleEffect(isProcessingPurchase ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isProcessingPurchase)
        }
        .disabled(isProcessingPurchase)
    }
    
    // 自定义金额卡片
    @ViewBuilder
    private func customAmountCard() -> some View {
        Button(action: {
            // TODO: 实现自定义金额功能
        }) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // 文本信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: .customAmount))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Choose your own amount")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
            )
        }
        .disabled(isProcessingPurchase)
    }
    
    // 处理打赏
    private func processDonation(option: DonationOption) {
        isProcessingPurchase = true
        
        // 模拟购买处理 (在实际应用中会调用StoreKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isProcessingPurchase = false
            
            // 模拟随机成功/失败 (实际应用中根据StoreKit结果)
            let success = Bool.random()
            
            if success {
                showThankYou = true
            } else {
                errorMessage = String(localized: .purchaseFailed)
                showError = true
            }
        }
    }
}

// 预览
struct DonationView_Previews: PreviewProvider {
    static var previews: some View {
        DonationView(isPresented: .constant(true))
    }
}