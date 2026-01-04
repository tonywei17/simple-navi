import SwiftUI
import CoreLocation

struct CompassView: View {
    @Binding var showSettings: Bool
    @State private var viewModel = CompassViewModel()
    private var localizationManager = LocalizationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityAssistiveAccessEnabled) private var assistiveAccessEnabled
    @State private var showDonation = false
    
    init(showSettings: Binding<Bool>) {
        self._showSettings = showSettings
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 现代化渐变背景
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // 目的地卡片 - 在 Assistive Access 模式下隐藏以简化
                        if !viewModel.isAssistiveAccessEnabled {
                            if !viewModel.destinations.isEmpty && viewModel.selectedDestinationIndex < viewModel.destinations.count {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "house.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                        Text(localized: .destination)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    
                                    Text(viewModel.destinations[viewModel.selectedDestinationIndex].address)
                                        .font(.system(size: 20, weight: .semibold))
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // 现代化指南针
                        ZStack {
                            // 外圆环
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 6
                                )
                                .frame(width: viewModel.isAssistiveAccessEnabled ? 360 : 320, 
                                       height: viewModel.isAssistiveAccessEnabled ? 360 : 320)
                            
                            // 内圆背景
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.9),
                                            Color.blue.opacity(0.05)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 140
                                    )
                                )
                                .frame(width: 300, height: 300)
                                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                            
                            // 罗盘刻度和方向标识
                            Group {
                                // 方向刻度
                                ForEach(0..<8) { tick in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(tick % 2 == 0 ? Color.primary.opacity(0.8) : Color.primary.opacity(0.4))
                                        .frame(width: 3, height: tick % 2 == 0 ? 25 : 15)
                                        .offset(y: -140)
                                        .rotationEffect(.degrees(Double(tick) * 45))
                                }
                                
                                // 方向标识
                                ForEach(0..<4) { index in
                                    let directions = ["N", "E", "S", "W"]
                                    let angles = [0.0, 90.0, 180.0, 270.0]
                                    Text(directions[index])
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary.opacity(0.7))
                                        .offset(y: -100)
                                        .rotationEffect(.degrees(angles[index]))
                                }
                            }
                            .rotationEffect(.degrees(-viewModel.currentHeading))
                            
                            // 中心点
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                                .shadow(color: .blue.opacity(0.5), radius: 4)
                            
                            // 现代化箭头
                            CompassArrow(rotation: viewModel.arrowRotation + viewModel.spinAngle)
                                .contentShape(Circle())
                                .onTapGesture {
                                    viewModel.spinArrow()
                                }
                                .compositingGroup()
                                .sensoryFeedback(.impact(weight: .light, intensity: 1.0), trigger: viewModel.triggerAlignmentFeedback) { old, new in
                                    return new == true
                                }
                        }
                        .padding(.horizontal, 20)
                        
                        // 距离显示卡片
                        distanceCard
                        
                        // 底部地址图标切换
                        if !viewModel.isAssistiveAccessEnabled {
                            destinationIconSwitcher
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                        }
                        
                        // 底部间距
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if !viewModel.isAssistiveAccessEnabled {
                topBar
            }
        }
        .onAppear {
            viewModel.onAppear()
            viewModel.isAssistiveAccessEnabled = assistiveAccessEnabled
        }
        .onChange(of: showSettings) { _, newValue in
            viewModel.onSettingsChange(isShowing: newValue)
        }
        .onChange(of: scenePhase) { _, phase in
            viewModel.onScenePhaseChange(to: phase)
        }
        .onChange(of: assistiveAccessEnabled) { _, newValue in
            viewModel.isAssistiveAccessEnabled = newValue
        }
        .sheet(isPresented: $showDonation) {
            DonationView(isPresented: $showDonation)
        }
        .alert(String(localized: .locationNotSetTitle), isPresented: Binding(get: { viewModel.showSetupPrompt }, set: { viewModel.showSetupPrompt = $0 })) {
            Button(String(localized: .cancel), role: .cancel) {}
            Button(String(localized: .setupNow)) {
                showSettings = true
            }
        } message: {
            Text(String(localized: .locationNotSetMessage))
        }
    }
    
    private var distanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "ruler")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
                Text(localized: .distance)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if #available(iOS 16.0, *) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        distanceText
                        Text(localized: .meters)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer(minLength: 0)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        distanceText
                        Text(localized: .meters)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    distanceText
                    Text(localized: .meters)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    private var distanceText: some View {
        Text("\(Int(viewModel.distance))")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
            .animation(.easeInOut(duration: 0.3), value: viewModel.distance)
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { showDonation = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text(localized: .donate)
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: { showSettings = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text(localized: .settings)
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
    
    private var destinationIconSwitcher: some View {
        HStack(spacing: 28) {
            ForEach(0..<3, id: \.self) { slot in
                let addr = viewModel.slotAddresses[slot]
                let isAvailable = !addr.isEmpty
                let isSelected = isAvailable && viewModel.currentSlotIndex() == slot
                
                Button(action: { viewModel.selectSlot(slot) }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(slotGradient(slot))
                                .opacity(isAvailable ? 1.0 : 0.25)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(lineWidth: isSelected ? 4 : 0)
                                        .foregroundStyle(LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing))
                                )
                                .shadow(color: (isSelected ? Color.green : Color.black).opacity(isAvailable ? 0.18 : 0.0), radius: isSelected ? 10 : 8, x: 0, y: 4)
                            Image(systemName: slotIconName(slot))
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .semibold))
                                .opacity(isAvailable ? 1.0 : 0.5)
                        }
                        Text(viewModel.labelForSlot(slot))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isAvailable ? Color(UIColor.label) : Color(UIColor.tertiaryLabel))
                            .frame(width: 60)
                            .minimumScaleFactor(0.9)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityShowsLargeContentViewer {
                    VStack(spacing: 12) {
                        Image(systemName: slotIconName(slot))
                            .font(.system(size: 60))
                        Text(viewModel.labelForSlot(slot))
                            .font(.system(size: 24, weight: .bold))
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
    
    private func slotIconName(_ slot: Int) -> String {
        switch slot {
        case 0: return "house.fill"
        case 1: return "building.2.fill"
        default: return "heart.fill"
        }
    }

    private func slotGradient(_ slot: Int) -> LinearGradient {
        switch slot {
        case 0: return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1: return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct CompassView_Previews: PreviewProvider {
    static var previews: some View {
        CompassView(showSettings: .constant(false))
    }
}
