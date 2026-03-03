import SwiftUI

/// Unified glass card modifier — uses Liquid Glass on iOS 26+, falls back to `.ultraThinMaterial` on earlier versions.
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(DesignTokens.accent.opacity(0.25), lineWidth: 1)
                )
        }
    }
}

extension View {
    /// Apply a glass card background that adapts to iOS version.
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
