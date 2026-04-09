import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $viewModel.tab) {
                    Text("Places").tag(SearchViewModel.Tab.places)
                    Text("People").tag(SearchViewModel.Tab.people)
                }
                .pickerStyle(.segmented)
                .padding()

                switch viewModel.tab {
                case .places:
                    PlacesSearchResults(viewModel: viewModel)
                case .people:
                    PeopleSearchResults(viewModel: viewModel)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: viewModel.tab == .places ? "Search places" : "Search people")
            .onChange(of: searchText) { _, new in
                Task { await viewModel.search(query: new) }
            }
            .onChange(of: viewModel.tab) { _, _ in
                Task { await viewModel.search(query: searchText) }
            }
        }
    }
}

private struct PlacesSearchResults: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        List(viewModel.places, id: \.self) { completion in
            VStack(alignment: .leading) {
                Text(completion.title).font(.subheadline)
                Text(completion.subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
    }
}

private struct PeopleSearchResults: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        List(viewModel.profiles) { profile in
            NavigationLink(value: profile) {
                UserRowView(profile: profile)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Profile.self) { profile in
            ProfileView(userId: profile.id)
        }
    }
}
