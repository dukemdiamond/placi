import Foundation
import Observation
import CoreLocation
import MapKit
import Supabase

@Observable
final class MapViewModel: NSObject, MKLocalSearchCompleterDelegate {
    var posts: [Post] = []
    var filter: Filter = .mine
    var pendingCoordinate: CLLocationCoordinate2D?

    // Search
    var searchText = ""
    var searchResults: [MKLocalSearchCompletion] = []
    var isSearching = false

    enum Filter { case mine, following }

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address, .query]
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

    // MARK: - Search

    func updateSearch(_ query: String) {
        searchText = query
        if query.isEmpty {
            searchResults = []
            isSearching = false
        } else {
            isSearching = true
            completer.queryFragment = query
        }
    }

    /// Resolve a completion to coordinates and return the region to fly to.
    func resolveLocation(_ completion: MKLocalSearchCompletion) async -> MKCoordinateRegion? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        guard let response = try? await search.start(),
              let item = response.mapItems.first else { return nil }
        searchText = ""
        searchResults = []
        isSearching = false
        return MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        searchResults = []
    }
}
