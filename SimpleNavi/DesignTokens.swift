import SwiftUI

/// 集中管理的设计令牌 — 琥珀金 + 钢蓝适老化配色方案
/// 所有视图应引用此处的常量，而非硬编码颜色/透明度值。
enum DesignTokens {

    // MARK: - 主色调（琥珀金系）

    /// 主强调色 — 温暖琥珀金（替代全局 .blue）
    static let accent = Color(red: 0.76, green: 0.60, blue: 0.33)        // #C29954
    /// 辅助深色 — 深铜（渐变搭配）
    static let accentDeep = Color(red: 0.60, green: 0.45, blue: 0.22)    // #997336
    /// 浅金色 — 用于选中高亮
    static let accentSubtle = Color(red: 0.85, green: 0.75, blue: 0.55)  // #D9BF8C

    // MARK: - 导航箭头色（钢蓝系）

    /// 箭头主色 — 沉稳钢蓝
    static let arrowPrimary = Color(red: 0.20, green: 0.50, blue: 0.70)  // #337FB3
    /// 箭头辅色 — 深钢蓝
    static let arrowSecondary = Color(red: 0.15, green: 0.38, blue: 0.55) // #26618C

    // MARK: - 功能色

    /// 北方向标识 — 暖红（比纯 .red 更柔和）
    static let northRed = Color(red: 0.80, green: 0.22, blue: 0.18)      // #CC382E
    /// 捐赠按钮主色 — 暖铜
    static let donatePrimary = Color(red: 0.78, green: 0.42, blue: 0.20) // #C76B33
    /// 捐赠按钮辅色
    static let donateSecondary = Color(red: 0.65, green: 0.30, blue: 0.15) // #A64D26

    // MARK: - 文字色（高对比度暖灰，替代 .secondary）

    /// 次要文字 — 比系统 .secondary 对比度更高的暖灰
    static let textSecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.72, green: 0.70, blue: 0.68, alpha: 1.0)
            : UIColor(red: 0.40, green: 0.38, blue: 0.36, alpha: 1.0)
    })

    // MARK: - 背景渐变（暖米色调）

    static let bgGradientStart = Color(red: 0.58, green: 0.50, blue: 0.38).opacity(0.08)
    static let bgGradientMiddle = Color(red: 0.65, green: 0.55, blue: 0.40).opacity(0.05)
    static let bgAmbient = Color(red: 0.76, green: 0.60, blue: 0.33).opacity(0.04)

    // MARK: - 对比度标准（适老化：更高最低值）

    static let shadowOpacity: CGFloat = 0.10
    static let tickMajorOpacity: CGFloat = 0.85
    static let tickMinorOpacity: CGFloat = 0.40
    static let directionLabelOpacity: CGFloat = 0.90
    static let ringStrokeOpacity: CGFloat = 0.55

    // MARK: - 字号下限

    static let minimumReadableSize: CGFloat = 18
    static let statusTextSize: CGFloat = 20

    // MARK: - 槽位渐变

    static func slotGradient(_ slot: Int) -> LinearGradient {
        switch slot {
        case 0: return LinearGradient(colors: [accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1: return LinearGradient(colors: [donatePrimary, donateSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [
            Color(red: 0.60, green: 0.45, blue: 0.50),
            Color(red: 0.48, green: 0.35, blue: 0.42)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
