import SwiftUI
import StoreKit

// MARK: - StoreKit 2 管理器（加载商品、处理购买、监听交易）
@MainActor
final class IAPManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    private var updatesTask: Task<Void, Never>? = nil

    // 统一的打赏商品 ID（请在 App Store Connect 中使用这些 ID 创建 IAP）
    static let productIDs: [String] = [
        "com.simplenavi.simplenavi.tip.small",
        "com.simplenavi.simplenavi.tip.medium",
        "com.simplenavi.simplenavi.tip.large"
    ]

    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            // 按照预设顺序排序 small, medium, large
            let order: [String: Int] = [
                "com.simplenavi.simplenavi.tip.small": 0,
                "com.simplenavi.simplenavi.tip.medium": 1,
                "com.simplenavi.simplenavi.tip.large": 2,
            ]
            self.products = fetched.sorted { (lhs, rhs) in
                (order[lhs.id] ?? 99) < (order[rhs.id] ?? 99)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func startTransactionListener() {
        updatesTask?.cancel()
        updatesTask = Task {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction: StoreKit.Transaction = try self.checkVerified(result)
                    await transaction.finish()
                } catch {
                    // 忽略单次交易验证错误，集中在 UI 层提示
                }
            }
        }
    }

    @discardableResult
    func purchase(product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction: StoreKit.Transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    private func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "IAP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction unverified"])
        case .verified(let safe):
            return safe
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
}

struct DonationView: View {
    @Binding var isPresented: Bool
    private var localizationManager = LocalizationManager.shared
    @StateObject private var iap = IAPManager()
    @State private var isProcessingPurchase = false
    @State private var showThankYou = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    // 商品 ID → UI 展示的映射（使用已存在的本地化文案与配色）
    private func uiForProduct(_ id: String) -> (title: LocalizedStringKey, desc: LocalizedStringKey, icon: String, gradient: LinearGradient) {
        switch id {
        case "com.simplenavi.simplenavi.tip.small":
            return (.coffeeRegular, .coffeeRegularDesc, "cup.and.saucer", LinearGradient(colors: [.brown, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
        case "com.simplenavi.simplenavi.tip.medium":
            return (.coffeeLatte, .coffeeLatteDesc, "cup.and.saucer.fill", LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
        default:
            return (.afternoonTea, .afternoonTeaDesc, "leaf.fill", LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationBarHidden(true)
        }
        .task {
            await iap.loadProducts()
            iap.startTransactionListener()
            if let err = iap.errorMessage, !err.isEmpty {
                errorMessage = err
                showError = true
            }
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
                // 更加柔和的背景
                ZStack {
                    Color(uiColor: .systemBackground)
                    
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.15),
                            Color.red.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Circle()
                        .fill(Color.pink.opacity(0.05))
                        .frame(width: 400, height: 400)
                        .blur(radius: 60)
                        .offset(x: 150, y: -200)
                }
                .ignoresSafeArea()
                
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
        VStack(spacing: 24) {
            heartIcon
            
            VStack(spacing: 12) {
                Text(String(localized: .supportDeveloper))
                    .font(.system(size: 40, weight: .black, design: .rounded))
                
                Text(String(localized: .donateMessage))
                    .font(.system(size: 22, weight: .bold))
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
            if iap.isLoading {
                ProgressView().padding(.vertical, 12)
            }
            ForEach(iap.products, id: \.id) { product in
                donationOptionCard(product: product)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var cancelButton: some View {
        Button(action: {
            isPresented = false
        }) {
            Text(String(localized: .cancel))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.05))
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
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
    private func donationOptionCard(product: Product) -> some View {
        Button(action: {
            processDonation(product: product)
        }) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    let ui = uiForProduct(product.id)
                    Circle()
                        .fill(ui.gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: ui.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // 文本信息
                VStack(alignment: .leading, spacing: 8) {
                    let ui = uiForProduct(product.id)
                    Text(String(localized: ui.title))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(String(localized: ui.desc))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 价格
                Text(product.displayPrice)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.primary)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
            .scaleEffect(isProcessingPurchase ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isProcessingPurchase)
        }
        .disabled(isProcessingPurchase)
    }
    
    
    
    // 处理打赏
    private func processDonation(product: Product) {
        isProcessingPurchase = true
        Task {
            do {
                let tx = try await iap.purchase(product: product)
                // 仅在交易成功验证通过时展示感谢
                if tx != nil {
                    showThankYou = true
                }
            } catch {
                errorMessage = error.localizedDescription.isEmpty ? String(localized: .purchaseFailed) : error.localizedDescription
                showError = true
            }
            isProcessingPurchase = false
        }
    }
}

// 预览
struct DonationView_Previews: PreviewProvider {
    static var previews: some View {
        DonationView(isPresented: .constant(true))
    }
}