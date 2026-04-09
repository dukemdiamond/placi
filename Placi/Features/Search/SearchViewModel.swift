import Foundation
import Observation
import MapKit

@Observable
final class SearchViewModel: NSObject, MKLocalSearchCompleterDelegate {
    var tab: Tab = .places
    var places: [MKLocalSearchCompletion] = []
    var profiles: [Profile] = []

    enum Tab { case places, people }

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    func search(query: String) async {
        guard !query.isEmpty else {
            places = []
            profiles = []
            return
        }
        switch tab {
        case .places:
            completer.queryFragment = query
        case .people:
            profiles = (try? await ProfileService.searchProfiles(query: query)) ?? []
        }
    }

    // MARK: MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        places = completer.results
    }
}
