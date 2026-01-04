# 开发日志 / Changelog

## [2025-01-05] - 代码质量优化和性能提升

### 修复 (Fixed)
- **内存泄漏问题 (高优先级)** 🔴
  - 修复所有 `Task` 没有正确取消导致的内存泄漏
  - 添加 `Task` 引用管理：`geocodingTask` 和 `initialGeocodingTask`
  - 在所有 Task 中添加 `Task.isCancelled` 检查和 `CancellationError` 处理
  - 添加 `.onDisappear` 生命周期方法清理所有异步任务
  - 替换 `DispatchWorkItem` 为 `Task.sleep`，使用 Swift 并发的内置防抖机制
  - 优化 `setEditableAddressProgrammatically` 使用 `Task` 替代 `DispatchQueue`

### 优化 (Optimized)
- **状态管理优化 (中优先级)** 🟡
  - 引入 `MapState` 和 `AddressState` 结构体组织相关状态
  - 减少分散的 `@State` 变量，提高代码可维护性
  - 状态变量分组更清晰：地图状态、地址状态、任务管理

- **错误处理改进 (中优先级)** 🟡
  - 创建 `AddressConfirmError` 枚举类型
  - 实现 `LocalizedError` 协议提供本地化错误描述
  - 区分不同类型的错误：地理编码失败、网络错误、取消等

- **性能优化 (低优先级)** 🟢
  - 添加 `.mapStyle(.standard(elevation: .flat))` 减少 3D 渲染开销
  - 优化地图配置，提升渲染性能

- **可访问性支持 (低优先级)** ♿️
  - 为 `TextField` 添加 `.accessibilityLabel` 和 `.accessibilityHint`
  - 为确认按钮添加可访问性标签和提示
  - 提升视障用户的使用体验

### 技术细节 (Technical Details)
- **文件**: `AddressMapConfirmView.swift`
- **关键修改**:
  1. **内存管理**: 所有 Task 都有引用并在视图消失时取消
  2. **状态结构化**: 使用 `MapState` 和 `AddressState` 组织状态
  3. **错误类型化**: `AddressConfirmError` 枚举提供类型安全的错误处理
  4. **性能优化**: `.mapStyle(.standard(elevation: .flat))` 减少渲染负担
  5. **可访问性**: 添加 VoiceOver 支持

### 代码质量提升 (Code Quality)
- ✅ 遵循 Swift 并发最佳实践
- ✅ 符合 Apple 官方内存管理指南
- ✅ 提高代码可测试性和可维护性
- ✅ 改善用户体验和可访问性
- ✅ 减少潜在的崩溃和内存问题

---

## [2025-01-04] - 地址确认页面布局优化

### 修复 (Fixed)
- **地址确认页面布局溢出问题**
  - 修复长地址文本不换行导致的水平溢出
  - 使用 `TextField(axis: .vertical)` 配合 `.fixedSize(horizontal: false, vertical: true)` 强制文本垂直换行
  - 移除所有 `UIScreen.main.bounds` 硬编码，改用纯 SwiftUI 布局约束
  - 使用 `safeAreaInset(edge: .bottom)` 确保底部按钮正确固定在安全区域内
  - 优化地图高度为动态范围 (minHeight: 200, maxHeight: 300) 配合 aspectRatio 保持稳定布局

- **地图标记交互优化**
  - 将地图标记从地理坐标绑定改为固定在屏幕中心
  - 移除 `Map` 的 `Annotation`，改用 `ZStack` 叠加固定标记
  - 用户拖动地图时，标记始终保持在屏幕中央，方便精确选择目标位置
  - 地图中心坐标实时更新，自动反向地理编码获取地址信息

### 技术细节 (Technical Details)
- **文件**: `AddressMapConfirmView.swift`
- **关键修改**:
  1. TextField 文本换行: `.fixedSize(horizontal: false, vertical: true)`
  2. 地图标记固定: 从 `Annotation(coordinate:)` 改为 `ZStack` 叠加视图
  3. 布局约束: 使用 `safeAreaInset` 替代手动计算安全区域
  4. 移除 `NavigationStack`，因为视图以 sheet 形式呈现

### 改进 (Improved)
- 提升了在物理设备上的布局稳定性
- 改善了长日文地址的显示效果
- 优化了地图标记的用户体验，更符合常见地图选点交互模式
