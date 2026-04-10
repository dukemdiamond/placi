import SwiftUI
import CoreLocation

struct AddPlaceView: View {
    var droppedCoordinate: CLLocationCoordinate2D? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddPlaceViewModel()
    @State private var mode: Mode = .search
    @State private var successPost: Post? = nil

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
            .navigationTitle("add a place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Nunito-Regular", size: 16))
                }
            }
            .navigationDestination(item: $viewModel.selectedPlace) { place in
                PostFormView(place: place, viewModel: viewModel) { post in
                    successPost = post
                }
            }
        }
        .onAppear {
            if droppedCoordinate != nil { mode = .pin }
        }
        .fullScreenCover(item: $successPost) { post in
            PostSuccessView(post: post) {
                successPost = nil
                dismiss()
            }
        }
    }
}
