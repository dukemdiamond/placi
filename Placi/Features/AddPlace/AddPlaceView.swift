import SwiftUI
import CoreLocation

struct AddPlaceView: View {
    var droppedCoordinate: CLLocationCoordinate2D? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddPlaceViewModel()
    @State private var mode: Mode = .search

    enum Mode: String, CaseIterable {
        case search = "Search"
        case pin = "Drop Pin"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                switch mode {
                case .search:
                    PlaceSearchView(viewModel: viewModel)
                case .pin:
                    PinDropView(viewModel: viewModel, initialCoordinate: droppedCoordinate)
                }

                Spacer()
            }
            .navigationTitle("Add a Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(item: $viewModel.selectedPlace) { place in
                PostFormView(place: place, viewModel: viewModel)
            }
        }
        .onAppear {
            if droppedCoordinate != nil { mode = .pin }
        }
    }
}
