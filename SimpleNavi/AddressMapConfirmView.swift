import SwiftUI
import MapKit
import CoreLocation

// MARK: - State Models
struct MapState {
    var position: MapCameraPosition = .automatic
    var selectedCoordinate: CLLocationCoordinate2D?
    var originalCoordinate: CLLocationCoordinate2D?
    var isLoading = false
}

struct AddressState {
    var centerAddress: String = ""
    var editableAddress: String = ""
    var userEdited: Bool = false
    var programmaticUpdate: Bool = false
}

// MARK: - Error Types
enum AddressConfirmError: LocalizedError {
    case geocodingFailed
    case reverseGeocodingFailed
    case networkError
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .geocodingFailed, .reverseGeocodingFailed:
            return String(localized: .reverseGeocodeFailed)
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .cancelled:
            return nil
        }
    }
}

struct AddressMapConfirmView: View {
    let address: String
    let initialCoordinate: CLLocationCoordinate2D?
    @Binding var isPresented: Bool
    @Binding var confirmedAddress: String
    @Binding var confirmedCoordinate: CLLocationCoordinate2D?
    
    private let addressManager = JapaneseAddressManager.shared
    
    // MARK: - State
    @State private var mapState = MapState()
    @State private var addressState = AddressState()
    @State private var errorMessage: String?
    @State private var geocodingTask: Task<Void, Never>?
    @State private var initialGeocodingTask: Task<Void, Never>?
    @StateObject private var locationProvider = OneShotLocationProvider()
    @State private var didCenterToUserLocation: Bool = false
    
    init(address: String, initialCoordinate: CLLocationCoordinate2D?, isPresented: Binding<Bool>, confirmedAddress: Binding<String>, confirmedCoordinate: Binding<CLLocationCoordinate2D?>) {
        self.address = address
        self.initialCoordinate = initialCoordinate
        self._isPresented = isPresented
        self._confirmedAddress = confirmedAddress
        self._confirmedCoordinate = confirmedCoordinate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 主滚动区域
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 地址信息卡片
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                            Text(localized: .addressConfirmation)
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localized: .targetAddress)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // 核心修复：强制限制 TextField 宽度并允许垂直增长
                            // 不使用任何 UIScreen 或 GeometryReader，纯靠布局约束
                            TextField("", text: $addressState.editableAddress, axis: .vertical)
                                .font(.system(size: 17, weight: .semibold))
                                .lineLimit(1...5)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel(String(localized: .targetAddress))
                                .accessibilityHint("编辑目标地址")
                                .onChange(of: addressState.editableAddress) { _, _ in
                                    if !addressState.programmaticUpdate { addressState.userEdited = true }
                                }
                        }
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 地图区域
                    ZStack {
                        Map(position: $mapState.position, interactionModes: .all) {
                            // 移除 Annotation，标记将固定在屏幕中心
                        }
                        .mapStyle(.standard(elevation: .flat))
                        .frame(minHeight: 200, maxHeight: 300)
                        .aspectRatio(1.2, contentMode: .fit)
                        .cornerRadius(24)
                        .onMapCameraChange { context in
                            mapCenterChanged(to: context.camera.centerCoordinate)
                        }

                        // 固定在屏幕中心的标记
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 40, height: 40)
                                .shadow(color: .red.opacity(0.3), radius: 8)
                            Image(systemName: "house.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        if mapState.isLoading {
                            RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.2))
                                .overlay(ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.2))
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            Text(errorMessage).font(.system(size: 14, weight: .medium)).foregroundColor(.orange)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                // 2. 固定底栏
                VStack(spacing: 12) {
                    Button(action: confirmLocation) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(localized: .confirmAddress)
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(mapState.selectedCoordinate != nil ? AnyShapeStyle(LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Color.gray.opacity(0.6)))
                        )
                    }
                    .disabled(mapState.selectedCoordinate == nil)
                    .accessibilityLabel(String(localized: .confirmAddress))
                    .accessibilityHint("确认选择的地址和位置")
                    
                    Button(action: { isPresented = false }) {
                        Text(localized: .cancel)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue.opacity(0.08)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12) 
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            setEditableAddressProgrammatically(address)
            locationProvider.start()
            if let initCoord = initialCoordinate {
                mapState.position = .camera(MapCamera(centerCoordinate: initCoord, distance: 1000))
                mapState.selectedCoordinate = initCoord
                mapState.originalCoordinate = initCoord
                initialGeocodingTask = Task {
                    do {
                        let addr = try await addressManager.reverseGeocodeCoordinate(initCoord)
                        
                        if Task.isCancelled { return }
                        
                        await MainActor.run {
                            addressState.centerAddress = addr
                            setEditableAddressProgrammatically(addr)
                        }
                    } catch is CancellationError {
                        return
                    } catch {
                        if Task.isCancelled { return }
                        
                        await MainActor.run {
                            let fallback = formattedCoordinateString(initCoord)
                            addressState.centerAddress = fallback
                            setEditableAddressProgrammatically(fallback)
                        }
                    }
                }
            } else {
                geocodeInitialAddress()
            }
        }
        .onChange(of: locationProvider.coordinate?.latitude) { _, _ in
            guard let coord = locationProvider.coordinate, address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !didCenterToUserLocation else { return }
            didCenterToUserLocation = true
            mapState.position = .camera(MapCamera(centerCoordinate: coord, distance: 1000))
            mapState.selectedCoordinate = coord
            mapState.originalCoordinate = coord
            
            initialGeocodingTask?.cancel()
            
            initialGeocodingTask = Task {
                do {
                    let addr = try await addressManager.reverseGeocodeCoordinate(coord)
                    
                    if Task.isCancelled { return }
                    
                    await MainActor.run {
                        addressState.centerAddress = addr
                        if addressState.editableAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            setEditableAddressProgrammatically(addr)
                        }
                        errorMessage = nil
                    }
                } catch is CancellationError {
                    return
                } catch {
                    if Task.isCancelled { return }
                    
                    await MainActor.run {
                        let fallback = formattedCoordinateString(coord)
                        addressState.centerAddress = fallback
                        if addressState.editableAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            setEditableAddressProgrammatically(fallback)
                        }
                        errorMessage = String(localized: .reverseGeocodeFailed)
                    }
                }
            }
        }
        .onDisappear {
            // 清理所有异步任务，防止内存泄漏
            geocodingTask?.cancel()
            initialGeocodingTask?.cancel()
        }
    }
    
    private func geocodeInitialAddress() {
        mapState.isLoading = true
        errorMessage = nil
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            mapState.isLoading = false
            return
        }
        
        initialGeocodingTask = Task {
            do {
                let coordinate = try await addressManager.geocodeAddress(trimmed)
                
                if Task.isCancelled {
                    await MainActor.run { mapState.isLoading = false }
                    return
                }
                
                await MainActor.run {
                    mapState.isLoading = false
                    mapState.selectedCoordinate = coordinate
                    mapState.originalCoordinate = coordinate
                    mapState.position = .camera(MapCamera(centerCoordinate: coordinate, distance: 1000))
                    errorMessage = nil
                }
            } catch is CancellationError {
                await MainActor.run { mapState.isLoading = false }
                return
            } catch {
                if Task.isCancelled {
                    await MainActor.run { mapState.isLoading = false }
                    return
                }
                
                await MainActor.run {
                    mapState.isLoading = false
                    errorMessage = String(localized: .reverseGeocodeFailed)
                }
            }
        }
    }
    
    private func mapCenterChanged(to coordinate: CLLocationCoordinate2D) {
        mapState.selectedCoordinate = coordinate
        
        geocodingTask?.cancel()
        
        geocodingTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(600))
                
                if Task.isCancelled { return }
                
                let addr = try await addressManager.reverseGeocodeCoordinate(coordinate)
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    addressState.centerAddress = addr
                    errorMessage = nil
                    setEditableAddressProgrammatically(addr)
                }
            } catch is CancellationError {
                return
            } catch {
                if Task.isCancelled { return }
                
                await MainActor.run {
                    let fallback = formattedCoordinateString(coordinate)
                    addressState.centerAddress = fallback
                    setEditableAddressProgrammatically(fallback)
                }
            }
        }
    }
    
    private func confirmLocation() {
        guard let coordinate = mapState.selectedCoordinate else { return }
        confirmedCoordinate = coordinate
        let centerTrimmed = addressState.centerAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmedAddress = (!addressState.userEdited && !centerTrimmed.isEmpty) ? centerTrimmed : (addressState.editableAddress.isEmpty ? address : addressState.editableAddress)
        isPresented = false
    }

    private func setEditableAddressProgrammatically(_ value: String) {
        addressState.programmaticUpdate = true
        addressState.editableAddress = value
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            addressState.programmaticUpdate = false
        }
    }

    private func formattedCoordinateString(_ coord: CLLocationCoordinate2D) -> String {
        "Lat: \(String(format: "%.5f", coord.latitude)), Lon: \(String(format: "%.5f", coord.longitude))"
    }
}
