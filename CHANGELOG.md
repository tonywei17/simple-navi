# 开发日志 / Changelog

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
