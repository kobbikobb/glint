import Foundation

enum AuthState: String, Codable {
    case disconnected, connected, expired
}

struct SourceConfig: Codable, Identifiable {
    let id: String
    var isEnabled: Bool
    var authState: AuthState
    var displayName: String
    var filterGroups: [String]
    var excludePatterns: [String]
}
