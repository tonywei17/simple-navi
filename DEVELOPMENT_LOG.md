# 简单导航 iOS App 开发日志

## 项目概述
- **项目名称**: 简单导航 (SimpleNavi)
- **目标用户**: 全球老年用户
- **核心功能**: 显示指向预设地址的箭头和距离，无需复杂地图界面
- **开发平台**: iOS (SwiftUI)
- **测试设备**: iPhone 12 mini

---

### 第十阶段: 地点设定稳定性修复 + 坐标持久化
**时间**: 2025-10-03
**问题**: 保存的地址在再次打开时被替换为其他行政区/邮编中心地址（例如固定变为“460-0001 … 三之丸 3-1-3 日本”）。

**根因**:
1. 仅保存了地址文本，没有保存确认时的坐标；再次进入会对文本重新地理编码，返回的坐标/反查地址不稳定。
2. 地图中心变化时曾覆盖用户输入文本，造成“漂移”。

**方案**: 文本+坐标“双持久化”，显示用文本，计算用坐标。

**主要改动**:
- `UserDefaultsKeys.swift`
  - 新增 `address{1,2,3}Lat/Lon` 用于存储三组地址的经纬度。
- `SetupView.swift` / `SetupViewSimple.swift`
  - `ModernAddressInputField` 增加 `slot` 参数（1/2/3）。
  - 打开 `AddressMapConfirmView` 时传入已保存坐标 `initialCoordinate`。
  - 关闭确认页时同时保存 `confirmedCoordinate`，地址清空则清理对应坐标。
- `AddressMapConfirmView.swift`
  - 新增 `initialCoordinate`，若存在则直接用其初始化地图，避免首次 geocode 漂移。
  - 去除对 `editableAddress` 的强制覆盖；但在“用户未手动编辑”时，允许用地图中心反查结果自动填充，确保与坐标一致。
  - “确认此地址”时，若用户未手动编辑，则以 `centerAddress`（地图中心反查）作为最终文本。
- `CompassView.swift`
  - `loadAddresses()` 优先读取已保存坐标；无坐标时仅首次 geocode 一次并立即持久化。

**验证用例**:
1. 保存“463-0032 愛知県 名古屋市 白山 3-903 日本”→ 退出重进 → 文本保持一致，地图居中在保存点。
2. 拖动地图后确认 → 文本更新为中心地址；再次进入仍保持。

**性能微优化（本阶段已落地）**:
- `CompassView.LocationManager`
  - 将 `headingFilter` 设为 1°，显著降低方向回调频率。
  - 进入设置页时暂停磁力计，返回时恢复。
- 箭头刷新 `updateArrowRotation()`
  - 小于 0.2° 的微小变化不触发动画，减少重绘。
- 调试日志
  - 方位打印包裹 `#if DEBUG`，避免 Release 噪音。

---

### 第十一阶段: 120Hz 渲染优化 + 1.2 发布
**时间**: 2025-10-03
**目标**: 在具备 ProMotion 的 iPhone 上让指南针旋转更顺滑（120Hz），同时保留点击箭头的“弹簧回弹”趣味动画。

**主要改动**:
- `Info.plist`
  - 新增 `CADisableMinimumFrameDurationOnPhone = true`，允许 120Hz 刷新。
- `CompassView.swift`
  - 新增前/后台与设备刷新率感知的“显示配置”档位：
    - 前台且高刷：`angleEpsilon = 0.06`、`arrowAnimDuration = 0.07`、`headingFilter = 0.5°`。
    - 被动/后台：`angleEpsilon = 0.18`、`arrowAnimDuration = 0.12`、`headingFilter = 1.5°`。
  - 常规指向更新采用短时线性动画；点击箭头的一圈旋转仍使用 `interpolatingSpring(stiffness: 120, damping: 10)`，保持弹性手感不变。

**构建与发布**:
- 清理资源告警：移除未在 `Contents.json` 引用的 App Icon 文件 `simple-navi-iOS-Default-1024x1024@1x.png`。
- 版本与构建号：`MARKETING_VERSION = 1.2`，`CURRENT_PROJECT_VERSION = 10`（Debug/Release 统一）。
- 以 tag `v1.2` 推送，Xcode Cloud 自动归档并上传 App Store Connect。

**验证**:
- 在 120Hz 设备上自然旋转手机，箭头跟随更连贯；点击箭头仍保留“旋转一圈+回弹”的动画风格。
- 非高刷设备维持既有流畅度与能耗平衡。

**兼容性**:
- iOS 15+ 目标版本不变；上述优化为参数级调整，无额外运行时依赖。

---

## 开发历程记录

### 第一阶段: 项目创建和基础功能
**时间**: 初期开发
**目标**: 创建基础的导航应用框架

**实现功能**:
1. 创建了 SwiftUI 项目结构
2. 实现了基础的地址设置界面 (SetupView)
3. 实现了指南针视图 (CompassView)
4. 集成了 Core Location 框架进行GPS定位
5. 添加了地理编码服务 (GeocodingService)

**关键文件**:
- `SimpleNaviApp.swift` - 应用入口点
- `ContentView.swift` - 主视图控制器
- `SetupView.swift` - 地址设置界面
- `CompassView.swift` - 指南针显示界面
- `GeocodingService.swift` - 地理编码服务

### 第二阶段: 用户界面现代化
**时间**: 中期开发
**问题**: 用户要求界面更现代化

**解决方案**:
1. 重新设计了UI，采用卡片式布局
2. 添加了渐变背景和阴影效果
3. 使用了现代的按钮设计
4. 优化了颜色搭配和字体

**修改文件**:
- 所有UI相关文件都进行了现代化改造

### 第三阶段: 指南针功能调试
**时间**: 中期开发
**问题**: 指南针不响应设备旋转，箭头方向不准确

**调试过程**:
1. **问题1**: 指南针启动后不响应手机旋转
   - **原因**: 缺少 CLLocationManager 的磁力计权限和代理设置
   - **解决**: 添加了 `CLLocationManagerDelegate` 和磁力计启动代码

2. **问题2**: 箭头指向错误方向
   - **原因**: 箭头计算逻辑错误，没有考虑设备当前朝向
   - **解决**: 修改计算公式为 `angle - locationManager.currentHeading`

3. **问题3**: 指南针表盘不随设备旋转
   - **原因**: 指南针应该像真实指南针一样，表盘随设备旋转，箭头指向地理方向
   - **解决**: 实现了正确的指南针逻辑

**关键代码修改**:
```swift
// CompassView.swift 中的关键修复
.rotationEffect(.degrees(angle - locationManager.currentHeading))
```

### 第四阶段: 日本地址支持优化
**时间**: 中期开发
**需求**: 用户在日本，需要优化日本地址输入和识别

**实现**:
1. 创建了 `JapaneseAddressManager.swift`
2. 添加了用户具体地址的坐标
3. 优化了地理编码服务对日本地址的处理

**测试地址**:
- 用户地址1: 愛知県名古屋市熱田区明野町2-10 フローレンス白鳥
- 用户地址2: 愛知県尾張旭市緑町緑丘-100-14-10

### 第五阶段: 地图确认功能
**时间**: 中期开发
**需求**: 为照顾老人的家属添加地图确认功能

**实现**:
1. 创建了 `AddressMapConfirmView.swift`
2. 集成了 Apple MapKit
3. 添加了交互式地图界面
4. 实现了地址坐标确认功能

**UI问题修复**:
- 修复了地图图标下白色背景问题
- 改为半透明黑色背景配白色文字

### 第六阶段: 多语言支持系统
**时间**: 中后期开发
**需求**: 支持全球用户，需要多语言界面

**实现**:
1. 创建了 `LocalizationManager.swift` - 完整的本地化管理系统
2. 创建了 `LanguageSelectionView.swift` - 语言选择界面
3. 支持语言: 英语、中文(简体)、日语

**语言管理系统特点**:
- 使用 ObservableObject 模式
- 支持实时语言切换
- 包含所有界面文本的翻译

### 第七阶段: 打赏功能
**时间**: 中后期开发
**需求**: 添加用户打赏支持功能

**实现**:
1. 创建了 `DonationView.swift`
2. 设计了咖啡主题的打赏选项
3. 支持多币种 (美元、人民币、日元)
4. 集成到主界面

**打赏选项**:
- 普通咖啡: $1.99 / ¥15 / ¥300
- 精品拿铁: $4.99 / ¥35 / ¥750  
- 惬意下午茶: $9.99 / ¥68 / ¥1500

### 第八阶段: UI细节优化
**时间**: 后期开发
**问题**: 设置页面间距过大，需要精确调整

**调整过程**:
1. 初始间距: 60px (用户反馈太大)
2. 调整到: 40px (仍然太大)
3. 调整到: 10px (还是太大)
4. 调整到: -20px (接近理想)
5. 最终: -40px (用户满意)

**最终代码**:
```swift
.padding(.top, -40) // 极致紧凑布局
```

### 第九阶段: 应用名称与本地化更新
**时间**: 2025-10-03
**需求**: 主屏幕和设置页使用新名称，并按语言显示

**实现**:
1. 更新 `LocalizationManager.swift`：
   - 中文名称改为「极简导航」
   - 日文名称改为「シンプルナビ」
   - 英文保持「Simple Navigation」
   - 设置页标题 `setupTitle` 同步更新
2. 新增 `InfoPlist.strings` 本地化文件：
   - `SimpleNavi/en.lproj/InfoPlist.strings`：`CFBundleDisplayName = "Simple Navigation";`
   - `SimpleNavi/zh-Hans.lproj/InfoPlist.strings`：`CFBundleDisplayName = "极简导航";`
   - `SimpleNavi/ja.lproj/InfoPlist.strings`：`CFBundleDisplayName = "シンプルナビ";`
3. 更新 Xcode 配置：
   - `project.pbxproj` 的 `knownRegions` 增加 `ja` 与 `zh-Hans`
   - Debug/Release 默认 `INFOPLIST_KEY_CFBundleDisplayName` 修改为 "Simple Navigation"

**注意**:
- 需在 Xcode 中将上述 `InfoPlist.strings` 作为 Variant Group 加入 Target 的 Resources，确保应用图标名称按语言显示。

---

## 当前重大问题: 语言选择器功能失效

### 问题描述
**发现时间**: 2025-09-09
**问题现象**: 
1. 语言选择按钮点击无反应
2. 语言选择界面无法弹出
3. 即使在调试模式下，LocalizationManager 本身工作正常

### 问题调试过程

#### 调试阶段1: 验证 LocalizationManager 核心功能
**方法**: 创建独立的 DebugView 测试语言管理器
**结果**: ✅ LocalizationManager 工作正常，可以正确切换语言
**结论**: 问题不在核心的语言管理逻辑

#### 调试阶段2: 定位UI层问题
**发现**: 
- LocalizationManager.shared 实例工作正常
- 语言选择按钮本身无法响应点击
- 问题出现在 SetupViewSimple 中的按钮绑定

#### 调试阶段3: 深度代码分析
**检查的组件**:
1. `LanguageSelectionView.swift` - 语言选择界面 ✅ 代码正确
2. `SetupViewSimple.swift` - 主设置界面的按钮绑定 ❓ 可能有问题
3. Sheet 展示机制 ❓ 可能有问题

**添加的调试代码**:
```swift
// SetupViewSimple.swift
Button(action: { 
    print("Language selection button tapped")
    showLanguageSelection = true 
    print("showLanguageSelection set to: \(showLanguageSelection)")
}) {
    // 按钮内容...
}

// LanguageSelectionView.swift  
Button(action: {
    print("Language button tapped: \(language.rawValue)")
    localizationManager.currentLanguage = language
    print("Language set to: \(localizationManager.currentLanguage.rawValue)")
    // 自动关闭语言选择页面
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        isPresented = false
    }
}) {
    // 按钮内容...
}
```

### 技术修复尝试

#### 尝试1: 修复LocalizationManager的UI更新机制
```swift
@Published var currentLanguage: SupportedLanguage = .chinese {
    willSet {
        objectWillChange.send()
    }
    didSet {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
    }
}
```

#### 尝试2: 创建响应式本地化组件
```swift
struct LocalizedText: View {
    let key: LocalizedStringKey
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Text(localizationManager.localizedString(key))
    }
}

struct LocalizedTextField: View {
    let placeholderKey: LocalizedStringKey
    @Binding var text: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        TextField(localizationManager.localizedString(placeholderKey), text: $text)
    }
}
```

#### 尝试3: 强制视图重新创建
```swift
// ContentView.swift
NavigationView {
    if isFirstLaunch || showSettings {
        SetupViewSimple(isFirstLaunch: $isFirstLaunch, showSettings: $showSettings)
            .id("setup-\(localizationManager.currentLanguage.rawValue)")
    } else {
        CompassView(showSettings: $showSettings)
            .id("compass-\(localizationManager.currentLanguage.rawValue)")
    }
}
```

### 当前状态
**问题状态**: 🔴 未解决
**最新发现**: 语言选择按钮点击完全无反应，问题比预期更严重
**下一步计划**: 
1. 查看Xcode调试控制台输出
2. 检查是否有Swift编译错误或运行时错误
3. 考虑完全重写语言选择机制

---

## 技术栈和依赖

### 核心技术
- **开发语言**: Swift 5
- **UI框架**: SwiftUI
- **iOS版本**: iOS 17.5+
- **Xcode版本**: Xcode 16F6

### 系统框架依赖
- `Core Location` - GPS定位和指南针
- `MapKit` - 地图显示和地址确认
- `SwiftUI` - 用户界面
- `Foundation` - 基础数据处理
- `UserDefaults` - 本地数据存储

### 项目文件结构
```
SimpleNavi/
├── SimpleNaviApp.swift          # 应用入口
├── ContentView.swift            # 主视图控制器
├── CompassView.swift           # 指南针界面
├── SetupViewSimple.swift       # 简化的设置界面
├── LanguageSelectionView.swift # 语言选择界面
├── AddressMapConfirmView.swift # 地图确认界面
├── DonationView.swift          # 打赏界面
├── LocalizationManager.swift   # 多语言管理
├── GeocodingService.swift      # 地理编码服务
├── JapaneseAddressManager.swift # 日本地址管理
├── CustomArrowView.swift       # 自定义箭头视图
├── DebugView.swift            # 调试界面
├── Assets.xcassets/           # 资源文件
└── Info.plist                 # 应用配置
```

---

## 遗留问题

### 高优先级问题
1. **语言选择器完全失效** 🔴
   - 按钮点击无反应
   - 需要深度调试或重写

2. **地图确认视图padding问题** 🟡
   - 已修改但用户报告未生效
   - 需要验证修改是否正确应用

### 中等优先级问题
1. **iOS版本兼容性警告**
   - `onChange(of:perform:)` 在iOS 17.0中已弃用
   - 需要更新到新的API

2. **MapKit API警告**
   - 某些MapKit初始化方法已弃用
   - 需要迁移到新的MapContentBuilder API

### 低优先级优化
1. **性能优化**
   - 减少不必要的视图重新创建
   - 优化LocationManager的更新频率

2. **用户体验改进**
   - 添加加载指示器
   - 优化动画效果

---

## 成功解决的问题记录

### ✅ 指南针方向计算问题
**问题**: 箭头指向错误，不随设备旋转正确更新
**解决**: 实现正确的角度计算公式 `angle - currentHeading`

### ✅ 项目文件损坏问题
**问题**: 修改project.pbxproj时导致项目无法编译
**解决**: 正确添加PBXBuildFile和项目引用

### ✅ 日本地址识别问题
**问题**: 用户的具体日本地址无法正确识别
**解决**: 添加预定义坐标和优化地理编码服务

### ✅ UI现代化
**问题**: 用户要求更现代的界面设计
**解决**: 实现渐变背景、卡片布局、现代按钮设计

### ✅ 多语言基础架构
**问题**: 需要支持多语言用户
**解决**: 创建完整的LocalizationManager系统(核心功能正常)

---

## 开发经验总结

### 技术学习点
1. **SwiftUI状态管理**: 学会了@Published、@ObservedObject的正确使用
2. **Core Location集成**: 掌握了GPS和指南针的iOS API使用
3. **项目配置管理**: 学会了手动修改Xcode项目文件
4. **调试技巧**: 掌握了print调试和Xcode调试控制台的使用

### 用户反馈处理
1. **迭代式改进**: 用户对UI间距的多次调整要求
2. **功能需求演进**: 从基础导航到地图确认到多语言支持
3. **实际使用场景**: 为老年用户和照顾者设计不同功能

### 代码质量改进
1. **模块化设计**: 将复杂视图拆分为独立文件
2. **错误处理**: 添加了调试日志和错误捕获
3. **可维护性**: 使用了清晰的命名和代码组织

---

## 待办事项 (TODO)

### 立即需要解决
- [ ] 修复语言选择器按钮点击问题
- [ ] 验证地图确认视图padding修改是否生效
- [ ] 添加SVG自定义箭头功能

### 近期计划
- [ ] 修复iOS API弃用警告
- [ ] 优化应用性能
- [ ] 添加错误处理和用户反馈

### 长期计划  
- [ ] 添加更多语言支持
- [ ] 实现应用内购买的打赏功能
- [ ] 添加使用统计和分析

---

**日志创建时间**: 2025-09-09
**最后更新**: 2025-10-03
**当前版本**: 开发版本
**测试状态**: 语言选择器功能待修复

2025-10-03:
- [x] Localization updates:
  - Created a new `LocalizedStringKey` enum for easier string localization
  - Created a new `LocalizationManager` class for managing the current language
  - Updated all views to use the new localization manager
  - Added Japanese language support