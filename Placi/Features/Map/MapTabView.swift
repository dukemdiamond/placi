import SwiftUI
import MapKit

struct MapTabView: View {
    @State private var viewModel = MapViewModel()
    @State private var selectedPost: Post?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showAddPlace = false

    var body: some View {
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
            .overlay(alignment: .topTrailing) {
                Picker("Filter", selection: $viewModel.filter) {
                    Text("Mine").tag(MapViewModel.Filter.mine)
                    Text("Following").tag(MapViewModel.Filter.following)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .padding()
            }
            // Long press to start pin drop
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
        .task { await viewModel.loadPosts() }
        .onChange(of: viewModel.filter) { _, _ in
            Task { await viewModel.loadPosts() }
        }
    }
}
