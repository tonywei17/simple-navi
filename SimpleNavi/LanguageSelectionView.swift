import SwiftUI
import UIKit

struct LanguageSelectionView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool

    var body: some View {
        // 顶层使用 ZStack 铺满渐变，确保标题 inset 区域下也有同样的背景
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
                .safeAreaInset(edge: .top) {
                    headerView
                        .padding(.top, 12)
                }
        }
    }
    
    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            // 语言选项
            VStack(spacing: 16) {
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    languageOption(language)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // 完成按钮
            Button(action: {
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text(localized: .done)
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        // 背景已移至顶层 ZStack，避免在不同容器层产生叠加灰阶
    }
    private func languageOption(_ language: SupportedLanguage) -> some View {
        Button(action: {
            localizationManager.currentLanguage = language
        }) {
            HStack(spacing: 16) {
                // 国旗
                Text(language.flag)
                    .font(.system(size: 32))
                
                // 语言名称
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // 显示语言的本地化名称
                    Text(getLanguageNativeName(language))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 选中状态
                if localizationManager.currentLanguage == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(
                        color: localizationManager.currentLanguage == language ? 
                            .blue.opacity(0.3) : .black.opacity(0.1),
                        radius: localizationManager.currentLanguage == language ? 8 : 4,
                        x: 0, 
                        y: localizationManager.currentLanguage == language ? 4 : 2
                    )
            )
            .scaleEffect(localizationManager.currentLanguage == language ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: localizationManager.currentLanguage)
        }
    }
    
    private func getLanguageNativeName(_ language: SupportedLanguage) -> String {
        switch language {
        case .english:
            return "English"
        case .chinese:
            return "简体中文"
        case .japanese:
            return "日本語"
        }
    }

    private var headerView: some View {
        VStack(spacing: 2) {
            Text(localized: .language)
                .font(.system(size: 20, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .foregroundColor(.primary)
            Text(localized: .selectLanguage)
                .font(.system(size: 13, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        // 去除毛玻璃背景，避免在全屏弹窗中出现灰色蒙层感
        .background(Color.clear)
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView(isPresented: .constant(true))
    }
}