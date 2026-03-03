import SwiftUI
import UIKit

struct LanguageSelectionView: View {
    private var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    @Environment(\.layoutMetrics) private var metrics

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignTokens.bgGradientStart, DesignTokens.bgGradientMiddle],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                headerView
                    .padding(.top, 24)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(SupportedLanguage.allCases, id: \.self) { language in
                            languageOption(language)
                        }
                    }
                    .padding(.horizontal, metrics.horizontalMargin)
                    .padding(.vertical, 8)
                }

                Spacer()

                doneButton
            }
            .frame(maxWidth: metrics.modalMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var doneButton: some View {
        Button(action: {
            isPresented = false
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                Text(localized: .done)
                    .font(.system(size: 24, weight: .black, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                LinearGradient(
                    colors: [DesignTokens.accent, DesignTokens.accentDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: DesignTokens.accent.opacity(0.25), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, metrics.horizontalMargin)
        .padding(.bottom, 24)
    }

    private func languageOption(_ language: SupportedLanguage) -> some View {
        Button(action: {
            Task { @MainActor in
                localizationManager.currentLanguage = language
            }
        }) {
            HStack(spacing: 16) {
                Text(language.flag)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(language.displayName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(getLanguageNativeName(language))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(DesignTokens.textSecondary)
                }
                
                Spacer()
                
                if localizationManager.currentLanguage == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignTokens.accent)
                }
            }
            .padding(20)
            .glassCard()
            .overlay(
                Group {
                    if localizationManager.currentLanguage == language {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [DesignTokens.accent.opacity(0.5), DesignTokens.accentDeep.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                    }
                }
            )
            .shadow(color: .black.opacity(DesignTokens.shadowOpacity), radius: 10, x: 0, y: 4)
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
        VStack(spacing: 8) {
            Text(localized: .language)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.primary)
            Text(localized: .selectLanguage)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DesignTokens.textSecondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 28)
        .padding(.horizontal, metrics.horizontalMargin)
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView(isPresented: .constant(true))
    }
}