import SwiftUI
import UIKit

struct LanguageSelectionView: View {
    private var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }

                Spacer()

                doneButton
            }
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
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
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
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if localizationManager.currentLanguage == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        localizationManager.currentLanguage == language 
                        ? AnyShapeStyle(LinearGradient(colors: [.blue.opacity(0.5), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(.white.opacity(0.5)),
                        lineWidth: localizationManager.currentLanguage == language ? 2 : 1
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
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
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView(isPresented: .constant(true))
    }
}