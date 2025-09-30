import XCTest
import CoreLocation
@testable import SimpleNavi

final class SimpleNaviTests: XCTestCase {
    func testCalculateDistance_zeroWhenSamePoint() {
        let a = Coordinates.nagoyaCenter
        let d = GeocodingService.shared.calculateDistance(from: a, to: a)
        XCTAssertEqual(d, 0, accuracy: 0.001)
    }

    func testCalculateBearing_eastFromEquator() {
        // From (0,0) to (0,1) should be ~90° (East)
        let from = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let to = CLLocationCoordinate2D(latitude: 0, longitude: 1)
        let b = GeocodingService.shared.calculateBearing(from: from, to: to)
        XCTAssertEqual(b, 90, accuracy: 0.5)
    }

    func testFormatJapaneseAddress_nonJPShouldRemain() {
        let input = "1600 Amphitheatre Pkwy, Mountain View"
        let output = JapaneseAddressManager.shared.formatJapaneseAddress(input)
        XCTAssertEqual(output, input.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
