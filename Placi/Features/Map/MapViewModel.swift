import Foundation
import Observation
import CoreLocation
import MapKit

@Observable
final class MapViewModel {
    var posts: [Post] = []
    var filter: Filter = .mine
    var pendingCoordinate: CLLocationCoordinate2D?

    enum Filter { case mine, following }

    private let locationManager = CLLocationManager()

    func requestLocationIfNeeded() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func loadPosts(userId: UUID) async {
        do {
            switch filter {
            case .mine:
                posts = try await PostService.fetchUserPosts(userId: userId)
            case .following:
                posts = try await PostService.fetchFeedPosts(userId: userId, range: 0...199)
            }
        } catch {}
    }
}
