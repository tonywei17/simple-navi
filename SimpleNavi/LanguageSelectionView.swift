import SwiftUI
import UIKit

struct LanguageSelectionView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Text(localized: .language)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(localized: .selectLanguage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
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
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar(.hidden)
        }
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
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView(isPresented: .constant(true))
    }
}