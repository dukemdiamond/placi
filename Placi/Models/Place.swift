import Foundation
import CoreLocation
import MapKit

struct Place: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    var category: String?
    var mapkitId: String?
    let createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude, category
        case mapkitId = "mapkit_id"
        case createdAt = "created_at"
    }
}

extension Place {
    /// Construct a Place from an MKMapItem returned by MKLocalSearch.
    init(from mapItem: MKMapItem) {
        self.id = UUID()
        self.name = mapItem.name ?? "Unknown Place"
        self.latitude = mapItem.placemark.coordinate.latitude
        self.longitude = mapItem.placemark.coordinate.longitude
        self.category = mapItem.pointOfInterestCategory?.rawValue
        // identifier is iOS 18+; fall back to nil on older versions
        if #available(iOS 18.0, *) {
            self.mapkitId = mapItem.identifier?.rawValue
        } else {
            self.mapkitId = nil
        }
        self.createdAt = Date()

        // Build a readable address string
        let placemark = mapItem.placemark
        let parts = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ].compactMap { $0 }
        self.address = parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
