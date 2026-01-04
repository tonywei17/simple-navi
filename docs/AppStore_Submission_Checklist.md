# SimpleNavi 提交审核检查清单

本清单覆盖 App Store 提交前必做事项、IAP（打赏）配置与测试、提交过程问卷以及常见被拒原因规避。按顺序勾选即可。

---

## 1. 账号与协议
- [ ] 已加入 Apple Developer Program，并确保账号在有效期内。
- [ ] App Store Connect → Agreements, Tax, and Banking：已签署 Paid Applications 协议，并完成银行与税务信息（IAP 必须）。

## 2. App 基本信息（App Store Connect）
- [ ] 已创建 App 记录，Bundle ID 与 Xcode 一致：`com.simplenavi.simplenavi`。
- [ ] 名称、子标题、主要语言、分类已设置；联系方式与支持网址、隐私政策链接已填写。
- [ ] Age Rating（年龄分级）已回答完毕。

## 3. App 隐私（App Privacy）
- [ ] Data Collection：如仅使用定位用于功能，不做跟踪，选择“用于应用功能”，并勾选“数据不与用户关联”。
- [ ] Tracking：如未做跨 App 或网站的跟踪，选择“否”。

## 4. 素材与本地化
- [ ] App 图标（1024×1024 PNG，无透明）。
- [ ] 截图：至少 6.7"（Pro Max）与 5.5"（iPhone 8 Plus）两组。
- [ ] 如果有多语言（中/日/英），准备对应本地化文案与截图（非必需，但推荐）。

## 5. 项目侧配置（Xcode）
- [ ] Target → General：版本号（Marketing Version）与 Build 号（Project Version）正确。
- [ ] Target → Signing & Capabilities：勾选 Automatically manage signing；添加 In‑App Purchase 能力。
- [ ] Info（或构建设置里的 InfoPlist Keys）：
  - [ ] NSLocationWhenInUseUsageDescription（当你使用定位时显示用途，已在工程设置中注入）
  - [ ] NSLocationAlwaysAndWhenInUseUsageDescription（如需要）
- [ ] 架构与最低 iOS 版本与项目一致（当前 iOS 17+）。

## 6. 内购（IAP）配置
- [ ] IAP 类型：Consumable（可重复购买的小额打赏）。
- [ ] Product ID 前缀与 Bundle ID 对齐：
  - small: `com.simplenavi.simplenavi.tip.small`
  - medium: `com.simplenavi.simplenavi.tip.medium`
  - large: `com.simplenavi.simplenavi.tip.large`
- [ ] 价格建议（可根据地区调整）：
  - small → Tier 2（约 $1.99）
  - medium → Tier 5（约 $4.99）
  - large → Tier 10（约 $9.99）
- [ ] IAP 本地化（见 `StoreKit/IAP_Localization.json` 与 `StoreKit/IAP_Localization.csv`）：
  - 英文（en-US）：Small/Medium/Large Tip + 简短描述
  - 日文（ja-JP）：小額/中額/大額のチップ + 简短描述
  - 简体中文（zh-Hans）：小额/中额/大额打赏 + 简短描述
- [ ] IAP 截图：非必填，但建议提供 Donation 页面截图。

## 7. StoreKit 2 集成（代码侧）
- [ ] 代码文件：`SimpleNavi/DonationView.swift`
  - [ ] 使用 `IAPManager` 加载商品/购买/监听交易。
  - [ ] Product IDs 与 ASC 一致（如上三项）。
  - [ ] 价格使用 `product.displayPrice` 自动本地化。
  - [ ] 仅在成功且交易验证通过时弹“感谢”提示；取消/挂起不提示。
- [ ] 可选：添加“恢复购买”按钮（Consumable 无恢复意义，可省略）。

## 8. 构建与上传
- [ ] Xcode 选择 Any iOS Device 或连接真机 → Product → Archive。
- [ ] Xcode Organizer → Distribute App → App Store Connect → Upload。
- [ ] 等待 ASC 处理构建（10–30 分钟）。

## 9. TestFlight 测试
- [ ] 内部测试（推荐）：添加团队成员，立刻可用。
- [ ] 外部测试：提交简短审核后发放公共链接或邀请测试者。
- [ ] 沙盒账号（可选）：ASC → Users and Access → Sandbox Testers；购买弹窗处登录沙盒账号。

## 10. 提交流程（Prepare for Submission）
- [ ] 选择构建（刚上传的版本）。
- [ ] 勾选要随本版本提交审核的 IAP 条目（small/medium/large）。
- [ ] Encryption（加密）：通常选择“使用标准加密（仅 TLS），符合豁免 (b)(2)”。
- [ ] Content Rights：无第三方受版权保护内容则选择“否”。
- [ ] Advertising Identifier：如未使用广告，选择“否”。
- [ ] App Review Notes（建议填写，加快审核）：
  - App 打赏入口：主页右上角心形按钮 → 进入 Donation 页面。
  - 定位用途：用于指向用户保存的目的地并显示距离，不在后台持续收集位置。
  - 内购为“打赏/小费”，不解锁额外功能、不提供对价回报。

## 11. 审核通过与发布
- [ ] 审核通过后：选择立即发布或 Phased Release（分阶段发布）。
- [ ] 监控崩溃与用户反馈，准备快速修复版本（若需要）。

---

## 附：常见被拒原因与规避
- [ ] IAP 未随版本勾选一并提交 → 记得在“Prepare for Submission”中选择 IAP 条目。
- [ ] 隐私问卷不一致 → 确保数据收集用途与代码实际一致（例如定位仅用于功能）。
- [ ] 定位用途描述模糊 → `NSLocationWhenInUseUsageDescription` 文案明确说明用途。
- [ ] 打赏描述暗示对价 → IAP 描述中避免“解锁/功能/权益”等措辞，强调“支持开发者”。
- [ ] 截图不符合设备尺寸 → 至少提供 6.7" 与 5.5" 尺寸。

---

## 提交所需素材一览
- App 图标 1024×1024
- 截图：6.7"、5.5"
- 本地化文案：名称、子标题、描述、关键词、隐私政策链接
- IAP 本地化文案（参见 `StoreKit/IAP_Localization.*`）
- 审核备注（可复用本清单中的说明）
