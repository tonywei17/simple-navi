import Foundation
import SwiftUI

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

// 本地化管理器
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: SupportedLanguage = .chinese {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    private init() {
        // 从UserDefaults加载保存的语言
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
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
    }
    
    func localizedString(_ key: LocalizedStringKey) -> String {
        return localizedStrings[currentLanguage]?[key] ?? localizedStrings[.english]?[key] ?? key.stringKey
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
    case enterHomeAddress = "enter_home_address"
    case enterWorkAddress = "enter_work_address"
    case enterOtherAddress = "enter_other_address"
    case saveSettings = "save_settings"
    case confirmOnMap = "confirm_on_map"
    
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
        .enterHomeAddress: "Enter home address",
        .enterWorkAddress: "Enter work address",
        .enterOtherAddress: "Enter other important address",
        .saveSettings: "Save Settings",
        .confirmOnMap: "Confirm on Map",
        
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
        .selectLanguage: "Select Language"
    ],
    
    .chinese: [
        .appName: "简单导航",
        .settings: "设置",
        .save: "保存",
        .cancel: "取消",
        .confirm: "确认",
        .back: "返回",
        .next: "下一步",
        .done: "完成",
        .loading: "加载中",
        .error: "错误",
        
        .setupTitle: "简单导航",
        .setupSubtitle: "设置重要地址",
        .address1Home: "地址 1 (家)",
        .address2Work: "地址 2 (工作)",
        .address3Other: "地址 3 (其他)",
        .enterHomeAddress: "请输入家庭地址",
        .enterWorkAddress: "请输入工作地址",
        .enterOtherAddress: "请输入其他重要地址",
        .saveSettings: "保存设置",
        .confirmOnMap: "在地图上确认地址",
        
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
        .selectLanguage: "选择语言"
    ],
    
    .japanese: [
        .appName: "簡単ナビゲーション",
        .settings: "設定",
        .save: "保存",
        .cancel: "キャンセル",
        .confirm: "確認",
        .back: "戻る",
        .next: "次へ",
        .done: "完了",
        .loading: "読み込み中",
        .error: "エラー",
        
        .setupTitle: "簡単ナビゲーション",
        .setupSubtitle: "重要な住所を設定",
        .address1Home: "住所 1 (自宅)",
        .address2Work: "住所 2 (職場)",
        .address3Other: "住所 3 (その他)",
        .enterHomeAddress: "自宅住所を入力してください",
        .enterWorkAddress: "職場住所を入力してください",
        .enterOtherAddress: "その他の重要な住所を入力してください",
        .saveSettings: "設定を保存",
        .confirmOnMap: "地図で確認",
        
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
        .selectLanguage: "言語を選択"
    ]
]

// SwiftUI扩展，用于简化本地化字符串的使用
extension Text {
    init(localized key: LocalizedStringKey) {
        self.init(LocalizationManager.shared.localizedString(key))
    }
}

extension String {
    init(localized key: LocalizedStringKey) {
        self = LocalizationManager.shared.localizedString(key)
    }
}