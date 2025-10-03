import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct AddressMapConfirmView: View {
    let address: String
    @Binding var isPresented: Bool
    @Binding var confirmedAddress: String
    @Binding var confirmedCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var addressManager = JapaneseAddressManager.shared
    @State private var region = MKCoordinateRegion(
        center: Coordinates.nagoyaCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var originalCoordinate: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var centerAddress: String = ""
    @State private var geocodeDebounceWorkItem: DispatchWorkItem?
    @State private var editableAddress: String = ""
    @State private var addressTextHeight: CGFloat = 60
    @StateObject private var locationProvider = OneShotLocationProvider()
    @State private var didCenterToUserLocation: Bool = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let isCompact: Bool = geometry.size.width <= 375 // iPhone 12 mini 等
                let outerPadding: CGFloat = isCompact ? 12 : 20
                let cardInnerPadding: CGFloat = isCompact ? 16 : 20
                let textInnerPadding: CGFloat = isCompact ? 10 : 12
                let availableTextWidth: CGFloat = max(100, geometry.size.width - 2*outerPadding - 2*cardInnerPadding - 2*textInnerPadding)
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
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                Text(localized: .addressConfirmation)
                                    .font(.system(size: 22, weight: .bold))
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localized: .targetAddress)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                AutoSizingTextView(text: $editableAddress, dynamicHeight: $addressTextHeight, font: UIFont.systemFont(ofSize: 18, weight: .semibold), availableWidth: availableTextWidth)
                                    .frame(height: max(60, addressTextHeight), alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, textInnerPadding)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .cornerRadius(12)
                            }
                        }
                        .padding(cardInnerPadding)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                        )
                        .padding(.horizontal, outerPadding)
                        .padding(.top, 24)
                        .clipped()
                        
                        // 地图视图（中心固定标记，可拖动微调）
                        VStack(spacing: 12) {
                            HStack {
                                Text(localized: .addressConfirmation)
                                    .font(.system(size: 18, weight: .semibold))
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, outerPadding)
                            .clipped()

                            ZStack {
                                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: false)
                                    .frame(height: max(220, min(300, geometry.size.height * 0.4)))
                                    .cornerRadius(16)
                                    .onChange(of: region.center.latitude) { _ in
                                        mapCenterChanged()
                                    }
                                    .onChange(of: region.center.longitude) { _ in
                                        mapCenterChanged()
                                    }

                                // 中心固定的目的地标记（不拦截手势）
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
                                    Text(localized: .targetAddress)
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
                                .allowsHitTesting(false)

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
                                    Text(localized: .confirmAddress)
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
                                Text(localized: .cancel)
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
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, outerPadding)
                        .padding(.bottom, 20)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            editableAddress = address
            locationProvider.start()
            geocodeInitialAddress()
        }
        .onChange(of: locationProvider.coordinate?.latitude) { _ in
            // 当初始地址为空且首次拿到用户定位时，用用户定位作为中心并反查地址
            guard let coord = locationProvider.coordinate, address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !didCenterToUserLocation else { return }
            didCenterToUserLocation = true
            let regionSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            region = MKCoordinateRegion(center: coord, span: regionSpan)
            selectedCoordinate = coord
            originalCoordinate = coord
            // 自动显示当前位置的地址
            addressManager.reverseGeocodeCoordinate(coord) { result in
                switch result {
                case .success(let addr):
                    centerAddress = addr
                    if editableAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        editableAddress = addr
                    }
                    errorMessage = nil
                case .failure:
                    let fallback = formattedCoordinateString(coord)
                    centerAddress = fallback
                    if editableAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        editableAddress = fallback
                    }
                    errorMessage = String(localized: .reverseGeocodeFailed)
                }
            }
        }
        
    }
    
    private func geocodeInitialAddress() {
        isLoading = true
        errorMessage = nil
        
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // 若没有初始文本地址，则使用当前地图中心进行反向地理编码，避免报错
            isLoading = false
            let center = region.center
            selectedCoordinate = center
            originalCoordinate = center
            addressManager.reverseGeocodeCoordinate(center) { result in
                switch result {
                case .success(let addr):
                    centerAddress = addr
                    if editableAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        editableAddress = addr
                    }
                    errorMessage = nil
                case .failure:
                    let fallback = formattedCoordinateString(center)
                    centerAddress = fallback
                    if editableAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        editableAddress = fallback
                    }
                    errorMessage = String(localized: .reverseGeocodeFailed)
                }
            }
            return
        }
        
        addressManager.geocodeAddress(trimmed) { result in
            isLoading = false
            
            switch result {
            case .success(let coordinate):
                selectedCoordinate = coordinate
                originalCoordinate = coordinate
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                errorMessage = nil
                
            case .failure:
                errorMessage = String(localized: .reverseGeocodeFailed)
                // 回退：使用当前地图中心做反向地理编码以显示可用地址
                let center = region.center
                selectedCoordinate = center
                if originalCoordinate == nil { originalCoordinate = center }
                addressManager.reverseGeocodeCoordinate(center) { result in
                    if case .success(let addr) = result {
                        centerAddress = addr
                        editableAddress = addr
                        errorMessage = nil
                    } else {
                        let fallback = formattedCoordinateString(center)
                        centerAddress = fallback
                        editableAddress = fallback
                        errorMessage = String(localized: .reverseGeocodeFailed)
                    }
                }
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
        let text = editableAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmedAddress = text.isEmpty ? address : text
        isPresented = false
    }

    private func mapCenterChanged() {
        // 地图中心变化即视为用户微调
        let center = region.center
        selectedCoordinate = center
        // 可选：如果需要判断偏移距离，可在此保留计算，但目前不再用于提示 UI
        // 反向地理编码（防抖）
        geocodeDebounceWorkItem?.cancel()
        let work = DispatchWorkItem { [center] in
            addressManager.reverseGeocodeCoordinate(center) { result in
                switch result {
                case .success(let addr):
                    centerAddress = addr
                    editableAddress = addr
                    errorMessage = nil
                case .failure:
                    let fallback = formattedCoordinateString(center)
                    centerAddress = fallback
                    editableAddress = fallback
                    errorMessage = String(localized: .reverseGeocodeFailed)
                }
            }
        }
        geocodeDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    private func geodesicDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let l1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let l2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return l1.distance(from: l2)
    }

    private func formattedCoordinateString(_ coord: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.5f", coord.latitude)
        let lon = String(format: "%.5f", coord.longitude)
        // 简单的备用展示格式（可后续做本地化）
        return "Lat: \(lat), Lon: \(lon)"
    }

    // MARK: - Auto sizing UITextView wrapper for full, non-scrolling address display
    struct AutoSizingTextView: UIViewRepresentable {
        @Binding var text: String
        @Binding var dynamicHeight: CGFloat
        var font: UIFont = .systemFont(ofSize: 17)
        var availableWidth: CGFloat? = nil

        func makeUIView(context: Context) -> UITextView {
            let tv = UITextView()
            tv.isScrollEnabled = false
            tv.text = text
            tv.font = font
            tv.backgroundColor = .clear
            tv.textContainerInset = .zero
            tv.textContainer.lineFragmentPadding = 0
            tv.textContainer.lineBreakMode = .byCharWrapping // 对 CJK/长串字符使用按字符换行，避免小屏溢出
            tv.textAlignment = .natural
            tv.textContainer.widthTracksTextView = true
            tv.setContentCompressionResistancePriority(.required, for: .vertical)
            tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
            tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
            tv.delegate = context.coordinator
            return tv
        }

        func updateUIView(_ uiView: UITextView, context: Context) {
            if uiView.text != text { uiView.text = text }
            if uiView.font != font { uiView.font = font }
            uiView.invalidateIntrinsicContentSize()
            uiView.layoutIfNeeded()
            recalcHeight(view: uiView)
        }

        func makeCoordinator() -> Coordinator { Coordinator(self) }

        private func recalcHeight(view: UITextView) {
            let widthCandidate = availableWidth ?? view.bounds.width
            let width = max(1, widthCandidate)
            let size = view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            if dynamicHeight != size.height {
                DispatchQueue.main.async {
                    self.dynamicHeight = size.height
                }
            }
        }

        final class Coordinator: NSObject, UITextViewDelegate {
            var parent: AutoSizingTextView
            init(_ parent: AutoSizingTextView) { self.parent = parent }
            func textViewDidChange(_ textView: UITextView) {
                parent.text = textView.text
                parent.recalcHeight(view: textView)
            }
        }
    }
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