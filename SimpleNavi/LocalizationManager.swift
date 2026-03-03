import SwiftUI
import CoreLocation
import Observation

// 支持的语言
enum SupportedLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh-Hans"
    case japanese = "ja"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .chinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        }
    }
}

/// Localization manager modernized with @Observable for 2026.
@Observable
@MainActor
class LocalizationManager {
    static let shared = LocalizationManager()

    // 线程安全的缓存，供非主线程访问本地化字符串
    // swiftlint:disable:next nonisolated_unsafe
    nonisolated(unsafe) private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var stringCache: [String: String] = [:]

    var currentLanguage: SupportedLanguage = .chinese {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: UDKeys.selectedLanguage)
            Self.rebuildCache(for: currentLanguage)
        }
    }

    private init() {
        // 从UserDefaults加载保存的语言
        if let savedLanguage = UserDefaults.standard.string(forKey: UDKeys.selectedLanguage),
           let language = SupportedLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // 根据系统语言自动选择
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"

            switch systemLanguage {
            case "zh":
                currentLanguage = .chinese
            case "ja":
                currentLanguage = .japanese
            default:
                currentLanguage = .english
            }
        }
        Self.rebuildCache(for: currentLanguage)
    }

    /// Return a localized string for the given key, falling back to English if missing.
    func localizedString(_ key: LocalizedStringKey) -> String {
        return localizedStrings[currentLanguage]?[key] ?? localizedStrings[.english]?[key] ?? key.stringKey
    }

    /// 重建线程安全缓存（语言切换时调用）
    private static func rebuildCache(for language: SupportedLanguage) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        stringCache.removeAll()
        for key in LocalizedStringKey.allCases {
            stringCache[key.rawValue] = localizedStrings[language]?[key]
                ?? localizedStrings[.english]?[key]
                ?? key.stringKey
        }
    }

    /// 线程安全的缓存读取，供非主线程使用
    nonisolated static func cachedString(for key: LocalizedStringKey) -> String {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return stringCache[key.rawValue] ?? key.stringKey
    }
}

// 本地化字符串键
enum LocalizedStringKey: String, CaseIterable {
    // 通用
    case appName = "app_name"
    case settings = "settings"
    case save = "save"
    case cancel = "cancel"
    case confirm = "confirm"
    case yes = "yes"
    case no = "no"
    case back = "back"
    case next = "next"
    case done = "done"
    case loading = "loading"
    case error = "error"
    
    // 设置界面
    case setupTitle = "setup_title"
    case setupSubtitle = "setup_subtitle"
    case address1Home = "address1_home"
    case address2Work = "address2_work"
    case address3Other = "address3_other"
    case labelEditorTitle = "label_editor_title"
    case labelEditorMessage = "label_editor_message"
    case labelEditorPlaceholder = "label_editor_placeholder"
    case enterHomeAddress = "enter_home_address"
    case enterWorkAddress = "enter_work_address"
    case enterOtherAddress = "enter_other_address"
    case saveSettings = "save_settings"
    case confirmOnMap = "confirm_on_map"
    case useNagoyaSamples = "use_nagoya_samples"
    case commonNagoyaAddresses = "common_nagoya_addresses"
    case addressSuggestions = "address_suggestions"
    case hide = "hide"
    // 地址格式提示
    case addressFormatValid = "address_format_valid"
    case addressFormatSuggestion = "address_format_suggestion"
    
    // 指南针界面
    case destination = "destination"
    case distance = "distance"
    case meters = "meters"
    case selectDestination = "select_destination"
    case home = "home"
    case work = "work"
    case other = "other"
    
    // 地图确认界面
    case addressConfirmation = "address_confirmation"
    case targetAddress = "target_address"
    case landmarks = "landmarks"
    case confirmAddress = "confirm_address"
    case addressNotFound = "address_not_found"
    case searchingAddress = "searching_address"
    
    // 语言设置
    case language = "language"
    case selectLanguage = "select_language"
    
    // 打赏相关
    case donate = "donate"
    case supportDeveloper = "support_developer"
    case donateMessage = "donate_message"
    case coffeeRegular = "coffee_regular"
    case coffeeLatte = "coffee_latte"
    case afternoonTea = "afternoon_tea"
    case coffeeRegularDesc = "coffee_regular_desc"
    case coffeeLatteDesc = "coffee_latte_desc"
    case afternoonTeaDesc = "afternoon_tea_desc"
    case customAmount = "custom_amount"
    case customAmountHint = "custom_amount_hint"
    case thankYou = "thank_you"
    case purchaseComplete = "purchase_complete"
    case purchaseFailed = "purchase_failed"
    case restorePurchases = "restore_purchases"
    
    // 未设置地点提示
    case locationNotSetTitle = "location_not_set_title"
    case locationNotSetMessage = "location_not_set_message"
    case setupNow = "setup_now"
    case mapAdjustedPrompt = "map_adjusted_prompt"
    case mapFinalNoticeTitle = "map_final_notice_title"
    case mapFinalNoticeMessage = "map_final_notice_message"
    case reverseGeocodeFailed = "reverse_geocode_failed"
    
    var stringKey: String {
        return self.rawValue
    }
}

// 本地化字符串字典
private let localizedStrings: [SupportedLanguage: [LocalizedStringKey: String]] = [
    .english: [
        .appName: "Simple Navigation",
        .settings: "Settings",
        .save: "Save",
        .cancel: "Cancel",
        .confirm: "Confirm",
        .back: "Back",
        .next: "Next",
        .done: "Done",
        .loading: "Loading",
        .error: "Error",
        
        .setupTitle: "Simple Navigation",
        .setupSubtitle: "Set Important Addresses",
        .address1Home: "Address 1 (Home)",
        .address2Work: "Address 2 (Work)",
        .address3Other: "Address 3 (Other)",
        .labelEditorTitle: "Custom Label",
        .labelEditorMessage: "Rename this address for easier identification.",
        .labelEditorPlaceholder: "Enter a label",
        .enterHomeAddress: "Enter home address",
        .enterWorkAddress: "Enter work address",
        .enterOtherAddress: "Enter other important address",
        .saveSettings: "Save Settings",
        .confirmOnMap: "Confirm on Map",
        .useNagoyaSamples: "Use Nagoya sample addresses",
        .commonNagoyaAddresses: "Common Nagoya Addresses",
        .addressSuggestions: "Address Suggestions",
        .hide: "Hide",
        .addressFormatValid: "Address format is valid",
        .addressFormatSuggestion: "Consider using a complete address format",
        
        .destination: "Destination",
        .distance: "Distance",
        .meters: "m",
        .selectDestination: "Select Destination",
        .home: "Home",
        .work: "Work",
        .other: "Other",
        
        .addressConfirmation: "Address Confirmation",
        .targetAddress: "Target Address",
        .landmarks: "Landmarks",
        .confirmAddress: "Confirm Address",
        .addressNotFound: "Address not found",
        .searchingAddress: "Searching address...",
        
        .language: "Language",
        .selectLanguage: "Select Language",
        
        .donate: "Donate",
        .supportDeveloper: "Support Developer",
        .donateMessage: "This app is completely free and ad-free. If it has helped you and your family, please consider supporting the developer.",
        .coffeeRegular: "Regular Coffee",
        .coffeeLatte: "Premium Latte", 
        .afternoonTea: "Afternoon Tea",
        .coffeeRegularDesc: "Stay alert",
        .coffeeLatteDesc: "Full of energy",
        .afternoonTeaDesc: "Thank you for your generosity",
        .customAmount: "Custom Amount",
        .customAmountHint: "Choose your own amount",
        .thankYou: "Thank You!",
        .purchaseComplete: "Purchase completed successfully",
        .purchaseFailed: "Purchase failed",
        .restorePurchases: "Restore Purchases"
        ,
        .locationNotSetTitle: "Location not set",
        .locationNotSetMessage: "You haven't set up this location yet. Would you like to set it up now?",
        .setupNow: "Set Up Now"
        ,
        .mapAdjustedPrompt: "Map position adjusted. Update address to match?",
        .yes: "Yes",
        .no: "No",
        .mapFinalNoticeTitle: "Notice",
        .mapFinalNoticeMessage: "Final location will follow the map position. The text address is for display only."
        ,
        .reverseGeocodeFailed: "Unable to obtain address for this location. Showing coordinates as fallback."
    ],
    
    .chinese: [
        .appName: "丢了吗",
        .settings: "设置",
        .save: "保存",
        .cancel: "取消",
        .confirm: "确认",
        .back: "返回",
        .next: "下一步",
        .done: "完成",
        .loading: "加载中",
        .error: "错误",

        .setupTitle: "丢了吗",
        .setupSubtitle: "极简导航 · 设置重要地址",
        .address1Home: "地址 1 (家)",
        .address2Work: "地址 2 (工作)",
        .address3Other: "地址 3 (其他)",
        .labelEditorTitle: "自定义标签",
        .labelEditorMessage: "为该地址设置一个更容易识别的标签。",
        .labelEditorPlaceholder: "输入标签",
        .enterHomeAddress: "请输入家庭地址",
        .enterWorkAddress: "请输入工作地址",
        .enterOtherAddress: "请输入其他重要地址",
        .saveSettings: "保存设置",
        .confirmOnMap: "在地图上确认地址",
        .useNagoyaSamples: "使用名古屋示例地址",
        .commonNagoyaAddresses: "常用名古屋地址",
        .addressSuggestions: "地址建议",
        .hide: "隐藏",
        .addressFormatValid: "地址格式正确",
        .addressFormatSuggestion: "建议使用完整的地址格式",
        
        .destination: "目的地",
        .distance: "距离",
        .meters: "米",
        .selectDestination: "选择目的地",
        .home: "家",
        .work: "工作",
        .other: "其他",
        
        .addressConfirmation: "地址位置确认",
        .targetAddress: "目标地址",
        .landmarks: "地标",
        .confirmAddress: "确认此地址",
        .addressNotFound: "未找到地址",
        .searchingAddress: "搜索地址中...",
        
        .language: "语言",
        .selectLanguage: "选择语言",
        
        .donate: "打赏",
        .supportDeveloper: "支持开发者",
        .donateMessage: "这个应用完全免费，也没有广告。如果它帮助到了您和您的家人，请考虑支持开发者。",
        .coffeeRegular: "一杯普通咖啡",
        .coffeeLatte: "一杯精品拿铁",
        .afternoonTea: "一份惬意下午茶",
        .coffeeRegularDesc: "保持清醒",
        .coffeeLatteDesc: "注入满满能量", 
        .afternoonTeaDesc: "感谢您的慷慨",
        .customAmount: "自定义金额",
        .customAmountHint: "自定义你希望支持的金额",
        .thankYou: "谢谢！",
        .purchaseComplete: "购买成功",
        .purchaseFailed: "购买失败",
        .restorePurchases: "恢复购买"
        ,
        .locationNotSetTitle: "未设置此地点",
        .locationNotSetMessage: "您尚未设置此地点，是否现在去设置？",
        .setupNow: "去设置"
        ,
        .mapAdjustedPrompt: "地图位置已调整，是否需要更新地址？",
        .yes: "是",
        .no: "否",
        .mapFinalNoticeTitle: "提示",
        .mapFinalNoticeMessage: "最终定位以地图为准，文字只是作为信息展示。"
        ,
        .reverseGeocodeFailed: "无法获取该位置的地址，已显示坐标作为替代。"
    ],
    
    .japanese: [
        .appName: "シンプルナビ",
        .settings: "設定",
        .save: "保存",
        .cancel: "キャンセル",
        .confirm: "確認",
        .back: "戻る",
        .next: "次へ",
        .done: "完了",
        .loading: "読み込み中",
        .error: "エラー",
        
        .setupTitle: "シンプルナビ",
        .setupSubtitle: "重要な住所を設定",
        .address1Home: "住所 1 (自宅)",
        .address2Work: "住所 2 (職場)",
        .address3Other: "住所 3 (その他)",
        .labelEditorTitle: "カスタムラベル",
        .labelEditorMessage: "この住所にわかりやすいラベルを設定しましょう。",
        .labelEditorPlaceholder: "ラベルを入力",
        .enterHomeAddress: "自宅住所を入力してください",
        .enterWorkAddress: "職場住所を入力してください",
        .enterOtherAddress: "その他の重要な住所を入力してください",
        .saveSettings: "設定を保存",
        .confirmOnMap: "地図で確認",
        .useNagoyaSamples: "名古屋のサンプル住所を使用",
        .commonNagoyaAddresses: "名古屋の一般的な住所",
        .addressSuggestions: "住所の提案",
        .hide: "非表示",
        .addressFormatValid: "住所の形式が正しいです",
        .addressFormatSuggestion: "完全な住所形式の入力をおすすめします",
        
        .destination: "目的地",
        .distance: "距離",
        .meters: "メートル",
        .selectDestination: "目的地を選択",
        .home: "自宅",
        .work: "職場",
        .other: "その他",
        
        .addressConfirmation: "住所位置確認",
        .targetAddress: "目標住所",
        .landmarks: "ランドマーク",
        .confirmAddress: "この住所を確認",
        .addressNotFound: "住所が見つかりません",
        .searchingAddress: "住所を検索中...",
        
        .language: "言語",
        .selectLanguage: "言語を選択",
        
        .donate: "寄付",
        .supportDeveloper: "開発者をサポート",
        .donateMessage: "このアプリは完全無料で広告もありません。あなたやご家族のお役に立ちましたら、開発者をサポートしていただけますと幸いです。",
        .coffeeRegular: "普通のコーヒー",
        .coffeeLatte: "プレミアムラテ",
        .afternoonTea: "優雅なアフタヌーンティー",
        .coffeeRegularDesc: "目覚めを保つ",
        .coffeeLatteDesc: "エネルギー満タン",
        .afternoonTeaDesc: "ご寛大なご支援に感謝",
        .customAmount: "カスタム金額",
        .customAmountHint: "支援したい金額を自由に設定",
        .thankYou: "ありがとうございます！",
        .purchaseComplete: "購入が完了しました",
        .purchaseFailed: "購入に失敗しました",
        .restorePurchases: "購入を復元"
        ,
        .locationNotSetTitle: "この場所は未設定です",
        .locationNotSetMessage: "この場所はまだ設定されていません。今すぐ設定しますか？",
        .setupNow: "設定へ"
        ,
        .mapAdjustedPrompt: "地図の位置が調整されました。住所を更新しますか？",
        .yes: "はい",
        .no: "いいえ",
        .mapFinalNoticeTitle: "お知らせ",
        .mapFinalNoticeMessage: "最終的な位置は地図の位置が優先されます。テキストの住所は参考情報です。"
        ,
        .reverseGeocodeFailed: "この位置の住所を取得できませんでした。代わりに座標を表示します。"
    ]
]

// SwiftUI扩展，用于简化本地化字符串的使用
extension Text {
    init(localized key: LocalizedStringKey) {
        // For SwiftUI Text, we can safely assume main actor since Text initialization happens on main thread
        let string = MainActor.assumeIsolated {
            LocalizationManager.shared.localizedString(key)
        }
        self.init(string)
    }
}

extension String {
    nonisolated init(localized key: LocalizedStringKey) {
        if Thread.isMainThread {
            self = MainActor.assumeIsolated {
                LocalizationManager.shared.localizedString(key)
            }
        } else {
            // 使用线程安全的缓存，避免 DispatchQueue.main.sync 死锁风险
            self = LocalizationManager.cachedString(for: key)
        }
    }
}