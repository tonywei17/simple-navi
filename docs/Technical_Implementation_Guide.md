# 技术实现指南 - 简单导航 (Simple Navi)

## 1. 系统架构 (Architecture)
本项目基于 **SwiftUI + MVVM** 架构，确保了声明式 UI 与逻辑的清晰分离。

### 1.1 核心层级
*   **View 层**: `CompassView` (主导航), `SetupView` (设置), `AddressMapConfirmView` (地图确认)。
*   **Logic 层 (ViewModel)**: `LocationManager` (定位与朝向), `GeocodingService` (地理编码接口)。
*   **Service 层**: `JapaneseAddressManager` (日式地址特化), `SecureStorage` (Keychain 加密存储)。
*   **Data 层**: `SharedDataStore` (App Group 数据流), `NaviSnapshot` (快照模型)。

## 2. 关键导航算法 (Navigation Algorithms)

### 2.1 方位角与指向 (Bearing & Heading)
*   **方位角计算**: 使用大圆路径公式计算当前位置到目的地的初向角。
*   **指向逻辑**: `显示角度 = 目标方位角 - 设备当前朝向`。
*   **设备适配**: 动态调整 `headingOrientation`（区分面朝上与垂直持机），对齐系统指南针表现。

### 2.2 顺滑旋转算法 (Shortest Path Animation)
通过 `wrapDelta` 归一化角度差到 `[-180, 180]` 区间，配合线性动画实现最短路径旋转，消除 0/360 度跨越时的转圈现象。

## 3. 性能与能耗优化 (Performance & Battery)
*   **动态更新频率**: 
    *   **前台**: 120Hz 适配，角度步进 0.5°，动画时长 0.1s。
    *   **后台/非活动**: 角度步进 1.5°，降低磁力计唤醒频率。
*   **数据节流 (Throttling)**: 对写入 App Group 的导航快照进行防抖处理，变动极小时（<2m 或 <1°）忽略写入。

## 4. 关键技术点
*   **日本地址深度适配**: 正则提取行政区划，解决无空格地址的编码难题。
*   **坐标防漂移**: 在地图确认阶段持久化经纬度，避免因文本编码不一致导致的导航偏移。
*   **Live Activities**: 通过 `ActivityKit` 封装，实现灵动岛与锁屏界面的实时数据推送。

## 5. 2026+ 未来演进 (Future Roadmap)

### 5.1 状态管理升级 (@Observable)
*   **目标**: 迁移 `CompassViewModel` 和 `LocalizationManager` 从 `ObservableObject` 到 Swift 5.9+ 的 `@Observable` 宏。
*   **优势**: 
    *   **粒度重绘**: 视图仅在其使用的特定属性更改时刷新，显著提升主页复杂动画下的能耗表现。
    *   **语法简化**: 移除 `@Published` 包装器，利用 `Bindable` 处理双向绑定。

### 5.2 深度辅助功能优化
*   **Assistive Access 适配**: 检测 iOS 18+ 的 `accessibilityAssistiveAccessEnabled` 环境值，当用户开启该模式时，自动简化界面至“仅箭头”模式。
*   **Large Content Viewer**: 为底部地址切换按钮实现 `accessibilityShowsLargeContentViewer`，允许视力极差的用户长按放大查看地点标签。

### 5.3 严格并发检查 (Swift 6)
*   **目标**: 开启全量 `Strict Concurrency Checking`。
*   **实现**: 利用已有的 `actor` (SecureStorage, SharedDataStore) 和 `@MainActor` (ViewModel) 结构，解决最后潜在的静态数据竞争。
