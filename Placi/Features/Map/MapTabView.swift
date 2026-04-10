import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = MapViewModel()
    @State private var selectedPost: Post?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showAddPlace = false
    @State private var showSearch = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(viewModel.posts) { post in
                        if let place = post.place {
                            Annotation(place.name, coordinate: place.coordinate) {
                                PlaceAnnotationView(post: post)
                                    .onTapGesture { selectedPost = post }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                .gesture(
                    LongPressGesture(minimumDuration: 0.6)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .onEnded { value in
                            if case .second(true, let drag) = value,
                               let point = drag?.location,
                               let coord = proxy.convert(point, from: .local) {
                                viewModel.pendingCoordinate = coord
                                showAddPlace = true
                            }
                        }
                )
            }

            // Top-right controls
            VStack(spacing: 10) {
                // Search button
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }

                // Mine / Following toggle
                Picker("Filter", selection: $viewModel.filter) {
                    Text("mine").tag(MapViewModel.Filter.mine)
                    Text("following").tag(MapViewModel.Filter.following)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
            }
            .padding(.top, 60)
            .padding(.trailing, 12)
        }
        // Bottom sheet for tapped annotation
        .sheet(item: $selectedPost) { post in
            PlaceBottomSheet(post: post)
                .presentationDetents([.height(320), .medium])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(320)))
        }
        // Add place from long-press pin
        .sheet(isPresented: $showAddPlace) {
            if let coord = viewModel.pendingCoordinate {
                AddPlaceView(droppedCoordinate: coord)
            }
        }
        // Search sheet
        .sheet(isPresented: $showSearch) {
            MapSearchSheet { region in
                cameraPosition = .region(region)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task {
            viewModel.requestLocationIfNeeded()
            if let userId = authManager.currentUserId {
                await viewModel.loadPosts(userId: userId)
            }
        }
        .onChange(of: viewModel.filter) { _, _ in
            Task {
                if let userId = authManager.currentUserId {
                    await viewModel.loadPosts(userId: userId)
                }
            }
        }
    }
}

// MARK: - Map Search Sheet

struct MapSearchSheet: View {
    var onSelectRegion: (MKCoordinateRegion) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var results: [MKLocalSearchCompletion] = []
    @State private var completer = SearchCompleterWrapper()

    var body: some View {
        NavigationStack {
            List(results, id: \.self) { result in
                Button {
                    Task {
                        if let region = await completer.resolve(result) {
                            onSelectRegion(region)
                            dismiss()
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(result.title)
                            .font(.custom("Nunito-SemiBold", size: 15))
                            .foregroundStyle(.primary)
                        if !result.subtitle.isEmpty {
                            Text(result.subtitle)
                                .font(.custom("Nunito-Regular", size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("search location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "city, landmark, address…")
            .onChange(of: searchText) { _, new in completer.update(new) }
            .onReceive(completer.$results) { results = $0 }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .font(.custom("Nunito-Regular", size: 16))
                }
            }
        }
    }
}

// MARK: - Completer wrapper

import Combine

final class SearchCompleterWrapper: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address, .query]
    }

    func update(_ query: String) {
        if query.isEmpty { results = []; return }
        completer.queryFragment = query
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> MKCoordinateRegion? {
        let request = MKLocalSearch.Request(completion: completion)
        guard let response = try? await MKLocalSearch(request: request).start(),
              let item = response.mapItems.first else { return nil }
        return MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }
}
