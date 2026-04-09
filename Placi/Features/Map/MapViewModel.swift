import Foundation
import Observation
import CoreLocation

@Observable
final class MapViewModel {
    var posts: [Post] = []
    var filter: Filter = .mine
    var pendingCoordinate: CLLocationCoordinate2D?

    enum Filter { case mine, following }

    func loadPosts() async {
        // TODO: switch on filter, fetch from Supabase
        // For now we load the current user's posts
    }
}
