import Foundation
import Observation

/// Root app state injected at the top level via @Environment.
/// Add cross-cutting state here as the app grows.
@Observable
final class AppEnvironment {
    var selectedTab: Tab = .home

    enum Tab: Int {
        case home, map, add, search, profile
    }
}
