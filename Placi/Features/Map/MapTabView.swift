import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = MapViewModel()
    @State private var selectedPost: Post?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showAddPlace = false

    var body: some View {
        ZStack(alignment: .top) {
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
                            guard !viewModel.isSearching else { return }
                            if case .second(true, let drag) = value,
                               let point = drag?.location,
                               let coord = proxy.convert(point, from: .local) {
                                viewModel.pendingCoordinate = coord
                                showAddPlace = true
                            }
                        }
                )
            }

            // Search + filter overlay
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search for a location…", text: Binding(
                        get: { viewModel.searchText },
                        set: { viewModel.updateSearch($0) }
                    ))
                    .font(.custom("Nunito-Regular", size: 15))
                    .autocorrectionDisabled()
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.updateSearch("")
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
                .padding(.top, 12)

                // Search results dropdown
                if !viewModel.searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.searchResults, id: \.self) { result in
                                Button {
                                    Task {
                                        if let region = await viewModel.resolveLocation(result) {
                                            cameraPosition = .region(region)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.title)
                                                .font(.custom("Nunito-SemiBold", size: 14))
                                                .foregroundStyle(.primary)
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.custom("Nunito-Regular", size: 12))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }
                                Divider().padding(.leading, 14)
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                }

                // Mine / Following toggle
                if !viewModel.isSearching {
                    Picker("Filter", selection: $viewModel.filter) {
                        Text("Mine").tag(MapViewModel.Filter.mine)
                        Text("Following").tag(MapViewModel.Filter.following)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                }

                Spacer()
            }
        }
        .sheet(item: $selectedPost) { post in
            PlaceBottomSheet(post: post)
                .presentationDetents([.height(320), .medium])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(320)))
        }
        .sheet(isPresented: $showAddPlace) {
            if let coord = viewModel.pendingCoordinate {
                AddPlaceView(droppedCoordinate: coord)
            }
        }
        .task {
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
