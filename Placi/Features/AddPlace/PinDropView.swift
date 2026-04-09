import SwiftUI
import MapKit
import CoreLocation

struct PinDropView: View {
    @Bindable var viewModel: AddPlaceViewModel
    var initialCoordinate: CLLocationCoordinate2D?

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var pinnedCoordinate: CLLocationCoordinate2D?
    @State private var isResolving = false

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    if let coord = pinnedCoordinate {
                        Annotation("", coordinate: coord) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color("PlaciAccent"))
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { location in
                    if let coord = proxy.convert(location, from: .local) {
                        pinnedCoordinate = coord
                    }
                }
            }

            VStack {
                Spacer()
                if let coord = pinnedCoordinate {
                    Button {
                        Task { await confirmPin(coord) }
                    } label: {
                        Label(isResolving ? "Resolving…" : "Confirm Pin", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("PlaciAccent"))
                    .disabled(isResolving)
                    .padding()
                } else {
                    Text("Tap the map to drop a pin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            if let coord = initialCoordinate {
                pinnedCoordinate = coord
                cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }

    private func confirmPin(_ coord: CLLocationCoordinate2D) async {
        isResolving = true
        defer { isResolving = false }

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        let placemark = placemarks?.first

        let name = [placemark?.name, placemark?.thoroughfare].compactMap { $0 }.first ?? "Dropped Pin"
        let address = [
            placemark?.subThoroughfare,
            placemark?.thoroughfare,
            placemark?.locality
        ].compactMap { $0 }.joined(separator: ", ")

        viewModel.selectedPlace = Place(
            id: UUID(),
            name: name,
            address: address.isEmpty ? nil : address,
            latitude: coord.latitude,
            longitude: coord.longitude,
            category: nil,
            mapkitId: nil,
            createdAt: Date()
        )
    }
}
