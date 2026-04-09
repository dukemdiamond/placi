import SwiftUI
import MapKit

struct PlaceSearchView: View {
    @Bindable var viewModel: AddPlaceViewModel
    @State private var searchText = ""
    @State private var completer = SearchCompleter()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search for a place...", text: $searchText)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, new in
                        completer.search(query: new)
                    }
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            List(completer.results, id: \.self) { completion in
                Button {
                    Task {
                        if let place = await completer.resolve(completion) {
                            viewModel.selectedPlace = place
                        }
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text(completion.title).font(.subheadline)
                        Text(completion.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - SearchCompleter helper

@Observable
final class SearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    func search(query: String) {
        completer.queryFragment = query
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> Place? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try? await search.start()
        guard let item = response?.mapItems.first else { return nil }
        return Place(from: item)
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
