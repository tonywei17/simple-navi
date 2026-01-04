import SwiftUI
import MapKit
import CoreLocation

struct AddressMapConfirmView: View {
    let address: String
    let initialCoordinate: CLLocationCoordinate2D?
    @Binding var isPresented: Bool
    @Binding var confirmedAddress: String
    @Binding var confirmedCoordinate: CLLocationCoordinate2D?
    
    private let addressManager = JapaneseAddressManager.shared
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var originalCoordinate: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var centerAddress: String = ""
    @State private var geocodeDebounceWorkItem: DispatchWorkItem?
    @State private var editableAddress: String = ""
    @State private var userEditedAddress: Bool = false
    @State private var programmaticUpdate: Bool = false
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
                            TextField("", text: $editableAddress, axis: .vertical)
                                .font(.system(size: 17, weight: .semibold))
                                .lineLimit(1...5)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                                .fixedSize(horizontal: false, vertical: true) // 关键：禁止水平增长，允许垂直增长
                                .onChange(of: editableAddress) { _, _ in
                                    if !programmaticUpdate { userEditedAddress = true }
                                }
                        }
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 地图区域
                    ZStack {
                        Map(position: $position, interactionModes: .all) {
                            // 移除 Annotation，标记将固定在屏幕中心
                        }
                        .frame(minHeight: 200, maxHeight: 300) // 动态高度范围
                        .aspectRatio(1.2, contentMode: .fit) // 保持比例，避免过长
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
                        
                        if isLoading {
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
                                .fill(selectedCoordinate != nil ? AnyShapeStyle(LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Color.gray.opacity(0.6)))
                        )
                    }
                    .disabled(selectedCoordinate == nil)
                    
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
                position = .camera(MapCamera(centerCoordinate: initCoord, distance: 1000))
                selectedCoordinate = initCoord
                originalCoordinate = initCoord
                Task {
                    do {
                        let addr = try await addressManager.reverseGeocodeCoordinate(initCoord)
                        await MainActor.run {
                            centerAddress = addr
                            setEditableAddressProgrammatically(addr)
                        }
                    } catch {
                        await MainActor.run {
                            let fallback = formattedCoordinateString(initCoord)
                            centerAddress = fallback
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
            position = .camera(MapCamera(centerCoordinate: coord, distance: 1000))
            selectedCoordinate = coord
            originalCoordinate = coord
            Task {
                do {
                    let addr = try await addressManager.reverseGeocodeCoordinate(coord)
                    await MainActor.run {
                        centerAddress = addr
                        if editableAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            setEditableAddressProgrammatically(addr)
                        }
                        errorMessage = nil
                    }
                } catch {
                    await MainActor.run {
                        let fallback = formattedCoordinateString(coord)
                        centerAddress = fallback
                        if editableAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            setEditableAddressProgrammatically(fallback)
                        }
                        errorMessage = String(localized: .reverseGeocodeFailed)
                    }
                }
            }
        }
    }
    
    private func geocodeInitialAddress() {
        isLoading = true
        errorMessage = nil
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            isLoading = false
            return
        }
        
        Task {
            do {
                let coordinate = try await addressManager.geocodeAddress(trimmed)
                await MainActor.run {
                    isLoading = false
                    selectedCoordinate = coordinate
                    originalCoordinate = coordinate
                    position = .camera(MapCamera(centerCoordinate: coordinate, distance: 1000))
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = String(localized: .reverseGeocodeFailed)
                }
            }
        }
    }
    
    private func mapCenterChanged(to coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        geocodeDebounceWorkItem?.cancel()
        let work = DispatchWorkItem {
            Task {
                do {
                    let addr = try await addressManager.reverseGeocodeCoordinate(coordinate)
                    await MainActor.run {
                        centerAddress = addr
                        errorMessage = nil
                        setEditableAddressProgrammatically(addr)
                    }
                } catch {
                    await MainActor.run {
                        let fallback = formattedCoordinateString(coordinate)
                        centerAddress = fallback
                        setEditableAddressProgrammatically(fallback)
                    }
                }
            }
        }
        geocodeDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }
    
    private func confirmLocation() {
        guard let coordinate = selectedCoordinate else { return }
        confirmedCoordinate = coordinate
        let centerTrimmed = centerAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmedAddress = (!userEditedAddress && !centerTrimmed.isEmpty) ? centerTrimmed : (editableAddress.isEmpty ? address : editableAddress)
        isPresented = false
    }

    private func setEditableAddressProgrammatically(_ value: String) {
        programmaticUpdate = true
        editableAddress = value
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.programmaticUpdate = false
        }
    }

    private func formattedCoordinateString(_ coord: CLLocationCoordinate2D) -> String {
        "Lat: \(String(format: "%.5f", coord.latitude)), Lon: \(String(format: "%.5f", coord.longitude))"
    }
}
