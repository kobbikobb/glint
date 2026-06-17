import Foundation
import AuthenticationServices

struct FacebookOAuthService {
    private let appId: String
    private let keychain: Keychain
    private let configStore: ConfigStore

    static let serviceName = "com.glint.facebook"
    static let accountName = "token"

    init(appId: String, configStore: ConfigStore) {
        self.appId = appId
        self.keychain = Keychain()
        self.configStore = configStore
    }

    var isConnected: Bool {
        (try? keychain.read(service: Self.serviceName, account: Self.accountName)) != nil
    }

    func connect() async throws {
        let redirectURI = "https://www.facebook.com/connect/login_success.html"
        let scopes = "public_profile,user_events"
        let state = UUID().uuidString

        var components = URLComponents(string: "https://www.facebook.com/v19.0/dialog/oauth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: appId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "token,granted_scopes"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "state", value: state),
        ]

        let callbackURL = try await authenticate(with: components.url!)

        guard let fragment = callbackURL.fragment else {
            throw FacebookOAuthError.missingFragment
        }

        let params = parseQuery(fragment)
        guard let token = params["access_token"], !token.isEmpty else {
            throw FacebookOAuthError.missingToken
        }

        try keychain.save(token, service: Self.serviceName, account: Self.accountName)

        var config = (try? configStore.sourceConfigs().first(where: { $0.id == "facebook" }))
            ?? SourceConfig(id: "facebook", isEnabled: true, authState: AuthState.disconnected, displayName: "Facebook", filterGroups: [], excludePatterns: [])
        config.authState = AuthState.connected
        try configStore.saveSourceConfig(config)
    }

    func disconnect() throws {
        try keychain.delete(service: Self.serviceName, account: Self.accountName)

        var configs = try configStore.sourceConfigs()
        if let i = configs.firstIndex(where: { $0.id == "facebook" }) {
            configs[i].authState = .disconnected
            try configStore.saveSourceConfig(configs[i])
        }
    }

    @MainActor
    private func authenticate(with url: URL) async throws -> URL {
        let provider = OAuthContextProvider()
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { url, error in
                _ = provider
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: FacebookOAuthError.unknown)
                }
            }
            session.presentationContextProvider = provider
            guard session.start() else {
                continuation.resume(throwing: FacebookOAuthError.startFailed)
                return
            }
        }
    }

    private func parseQuery(_ query: String) -> [String: String] {
        query.components(separatedBy: "&").reduce(into: [:]) { result, pair in
            let parts = pair.components(separatedBy: "=")
            if parts.count == 2 {
                result[parts[0]] = parts[1].removingPercentEncoding
            }
        }
    }
}

enum FacebookOAuthError: LocalizedError {
    case missingFragment
    case missingToken
    case startFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingFragment: return "Missing fragment in callback URL"
        case .missingToken: return "No access token in callback"
        case .startFailed: return "OAuth session failed to start"
        case .unknown: return "Unknown OAuth error"
        }
    }
}

private class OAuthContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApplication.shared.windows.first { $0.isVisible } ?? NSWindow()
    }
}
