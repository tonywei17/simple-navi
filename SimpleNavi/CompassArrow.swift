import SwiftUI
import UIKit

// 复用的指南针箭头组件：优先使用自定义图片资源，否则回退到 SF Symbols
struct CompassArrow: View {
    let rotation: Double // 传入 angle - currentHeading
    
    private func customArrowImage() -> UIImage? {
        // 支持多种命名，任意一个存在即使用
        let candidates = [
            "CompassArrowBlue",
            "compass_arrow_blue",
            "compass_arrow",
            "navigation_arrow_blue"
        ]
        for name in candidates {
            if let img = UIImage(named: name) { return img }
        }
        return nil
    }
    
    var body: some View {
        Group {
            if let uiImage = customArrowImage() {
                // 自定义图片（建议图片默认朝向为 45° NE）
                Image(uiImage: uiImage)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 84, height: 84)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                    .rotationEffect(.degrees(rotation - 45))
            } else {
                // 回退到 SF Symbol: location.fill（默认 45° NE）
                ZStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundColor(.black.opacity(0.08))
                        .offset(x: 3, y: 3)
                        .blur(radius: 2)
                        .rotationEffect(.degrees(rotation - 45))
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.6, blue: 1.0),
                                    Color.blue,
                                    Color.purple.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(rotation - 45))
                        .overlay(
                            Image(systemName: "location.fill")
                                .font(.system(size: 70, weight: .bold))
                                .foregroundStyle(.white.opacity(0.15))
                                .rotationEffect(.degrees(rotation - 45))
                                .blendMode(.overlay)
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 4)
                }
            }
        }
        .accessibilityLabel(Text("Compass Arrow"))
    }
}
