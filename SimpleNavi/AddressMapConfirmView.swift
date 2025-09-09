import SwiftUI
import MapKit
import CoreLocation

struct AddressMapConfirmView: View {
    let address: String
    @Binding var isPresented: Bool
    @Binding var confirmedAddress: String
    @Binding var confirmedCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var addressManager = JapaneseAddressManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.1815, longitude: 136.9066),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var mapItems: [MKMapItem] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var nearbyLandmarks: [MKMapItem] = []
    @State private var showLandmarks = true
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // 现代化背景
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.1),
                            Color.green.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // 地址信息卡片
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                Text("地址确认")
                                    .font(.system(size: 22, weight: .bold))
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("输入的地址:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(address)
                                    .font(.system(size: 18, weight: .semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        
                        // 地图视图
                        VStack(spacing: 12) {
                            HStack {
                                Text("地图位置确认")
                                    .font(.system(size: 18, weight: .semibold))
                                Spacer()
                                
                                Button(action: { showLandmarks.toggle() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: showLandmarks ? "eye.fill" : "eye.slash.fill")
                                        Text("地标")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            ZStack {
                                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: false, annotationItems: mapAnnotations) { item in
                                    MapAnnotation(coordinate: item.coordinate) {
                                        if item.isMainLocation {
                                            // 主要地址标记
                                            VStack(spacing: 4) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.red)
                                                        .frame(width: 40, height: 40)
                                                        .shadow(color: .red.opacity(0.3), radius: 8)
                                                    Image(systemName: "house.fill")
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                                Text("目标地址")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.black.opacity(0.7))
                                                            .shadow(color: .black.opacity(0.3), radius: 4)
                                                    )
                                            }
                                        } else if showLandmarks {
                                            // 地标标记
                                            VStack(spacing: 2) {
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 20, height: 20)
                                                Text(item.name)
                                                    .font(.system(size: 8, weight: .medium))
                                                    .foregroundColor(.blue)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 300)
                                .cornerRadius(16)
                                .onTapGesture(coordinateSpace: .local) { location in
                                    let coordinate = convertToCoordinate(location: location, in: geometry.size)
                                    handleMapTap(coordinate: coordinate)
                                }
                                
                                if isLoading {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.3))
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.5)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // 错误消息
                            if let errorMessage = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(errorMessage)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer()
                        
                        // 操作按钮
                        VStack(spacing: 16) {
                            Button(action: confirmLocation) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                    Text("确认此地址")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            selectedCoordinate != nil
                                            ? AnyShapeStyle(LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing))
                                            : AnyShapeStyle(Color.gray.opacity(0.6))
                                        )
                                        .shadow(
                                            color: selectedCoordinate != nil ? .green.opacity(0.3) : .clear,
                                            radius: 12, x: 0, y: 6
                                        )
                                )
                            }
                            .disabled(selectedCoordinate == nil)
                            .scaleEffect(selectedCoordinate != nil ? 1.0 : 0.98)
                            .animation(.easeInOut(duration: 0.2), value: selectedCoordinate != nil)
                            
                            Button(action: { isPresented = false }) {
                                Text("取消")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            geocodeInitialAddress()
        }
    }
    
    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        
        // 添加主要地址标记
        if let coordinate = selectedCoordinate {
            items.append(MapAnnotationItem(
                id: "main",
                coordinate: coordinate,
                name: "目标地址",
                isMainLocation: true
            ))
        }
        
        // 添加地标标记
        if showLandmarks {
            for (index, landmark) in nearbyLandmarks.enumerated() {
                if let coordinate = landmark.placemark.location?.coordinate {
                    items.append(MapAnnotationItem(
                        id: "landmark_\(index)",
                        coordinate: coordinate,
                        name: landmark.name ?? "地标",
                        isMainLocation: false
                    ))
                }
            }
        }
        
        return items
    }
    
    private func geocodeInitialAddress() {
        isLoading = true
        errorMessage = nil
        
        addressManager.geocodeAddress(address) { result in
            isLoading = false
            
            switch result {
            case .success(let coordinate):
                selectedCoordinate = coordinate
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                
                // 搜索附近地标
                addressManager.searchNearbyLandmarks(coordinate: coordinate) { landmarks in
                    nearbyLandmarks = landmarks
                }
                
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        
        // 获取该坐标的地址
        addressManager.reverseGeocodeCoordinate(coordinate) { result in
            switch result {
            case .success(let address):
                confirmedAddress = address
            case .failure:
                confirmedAddress = self.address // 保持原地址
            }
        }
    }
    
    private func convertToCoordinate(location: CGPoint, in size: CGSize) -> CLLocationCoordinate2D {
        let x = location.x / size.width
        let y = location.y / size.height
        
        let lon = region.center.longitude - region.span.longitudeDelta/2 + (region.span.longitudeDelta * Double(x))
        let lat = region.center.latitude + region.span.latitudeDelta/2 - (region.span.latitudeDelta * Double(y))
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func confirmLocation() {
        guard let coordinate = selectedCoordinate else { return }
        
        confirmedCoordinate = coordinate
        if confirmedAddress.isEmpty {
            confirmedAddress = address
        }
        isPresented = false
    }
}

// 地图标注项
struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let name: String
    let isMainLocation: Bool
}

struct AddressMapConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        AddressMapConfirmView(
            address: "愛知県名古屋市中区栄3-15-33",
            isPresented: .constant(true),
            confirmedAddress: .constant(""),
            confirmedCoordinate: .constant(nil)
        )
    }
}