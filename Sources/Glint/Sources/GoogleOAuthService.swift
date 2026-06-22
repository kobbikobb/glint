import Foundation
import CommonCrypto
import Network
import AppKit

final class GoogleOAuthService: @unchecked Sendable {
    private let clientId = GoogleSecrets.clientId
    private let clientSecret = GoogleSecrets.clientSecret
    private let keychain = Keychain()
    private let keychainService = "com.glint.google"
    private let keychainToken = "token"
    private let keychainRefresh = "refresh"
    private var refreshTask: Task<String, Error>?

    var isConnected: Bool {
        (try? keychain.read(service: keychainService, account: keychainToken)) != nil
    }

    func disconnect() {
        try? keychain.delete(service: keychainService, account: keychainToken)
        try? keychain.delete(service: keychainService, account: keychainRefresh)
    }

    func connect() async throws -> String {
        let verifier = genVerifier()
        let challenge = b64url(sha256(Data(verifier.utf8)))
        let port = UInt16.random(in: 49152...65535)
        let redirectURI = "http://127.0.0.1:\(port)"
        let scope = "https://www.googleapis.com/auth/calendar.readonly"
        let encScope = scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        let authURL = "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientId)&redirect_uri=\(redirectURI)&response_type=code&scope=\(encScope)&code_challenge=\(challenge)&code_challenge_method=S256&access_type=offline"

        let code = try await catchRedirect(port: port, authURL: authURL)
        return try await exchangeCode(code: code, verifier: verifier, redirectURI: redirectURI)
    }

    func getAccessToken() async throws -> String {
        if let token = readToken() {
            return token.accessToken
        }
        if let existing = refreshTask {
            return try await existing.value
        }
        let task = Task { [self] in
            defer { refreshTask = nil }
            guard let str = try? keychain.read(service: keychainService, account: keychainRefresh),
                  let rtData = str.data(using: .utf8),
                  let rt = try? JSONDecoder().decode(RefreshToken.self, from: rtData) else {
                throw OAuthError.notConnected
            }
            let token = try await refreshAccessToken(refreshToken: rt.value)
            saveToken(token)
            return token.accessToken
        }
        refreshTask = task
        return try await task.value
    }

    private func readToken() -> Token? {
        guard let str = try? keychain.read(service: keychainService, account: keychainToken),
              let data = str.data(using: .utf8),
              let token = try? JSONDecoder().decode(Token.self, from: data),
              !token.isExpired else { return nil }
        return token
    }

    private func saveToken(_ token: Token) {
        guard let data = try? JSONEncoder().encode(token),
              let str = String(data: data, encoding: .utf8) else { return }
        try? keychain.save(str, service: keychainService, account: keychainToken)
    }

    private func saveRefreshToken(_ token: String) {
        let rt = RefreshToken(value: token)
        guard let data = try? JSONEncoder().encode(rt),
              let str = String(data: data, encoding: .utf8) else { return }
        try? keychain.save(str, service: keychainService, account: keychainRefresh)
    }
}

// MARK: - OAuth flow

extension GoogleOAuthService {
    private func catchRedirect(port: UInt16, authURL: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!) else {
                continuation.resume(throwing: OAuthError.serverFailed)
                return
            }

            var didResume = false
            listener.newConnectionHandler = { connection in
                connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, _, _ in
                    guard let data = data, let request = String(data: data, encoding: .utf8),
                          let code = self.extractCode(from: request) else {
                        self.sendResponse(connection, status: 400, body: "Bad request")
                        return
                    }
                    if !didResume {
                        didResume = true
                        continuation.resume(returning: code)
                    }
                    self.sendResponse(connection, status: 200, body: "Authorized! You can close this tab.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { listener.cancel() }
                }
                connection.start(queue: .main)
            }

            listener.start(queue: .main)
            DispatchQueue.main.async {
                NSWorkspace.shared.open(URL(string: authURL)!)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
                if !didResume {
                    listener.cancel()
                    continuation.resume(throwing: OAuthError.timeout)
                }
            }
        }
    }

    private func extractCode(from request: String) -> String? {
        guard let line = request.split(separator: "\n").first,
              let path = line.split(separator: " ").dropFirst().first,
              let url = URL(string: String(path)),
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
        else { return nil }
        return code.removingPercentEncoding ?? code
    }

    private func sendResponse(_ conn: NWConnection, status: Int, body: String) {
        let html = "<html><body><h1>\(body)</h1></body></html>"
        let resp = "HTTP/1.1 \(status) OK\r\nContent-Length: \(html.utf8.count)\r\nContent-Type: text/html\r\n\r\n\(html)"
        conn.send(content: resp.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
    }
}

// MARK: - Token exchange

extension GoogleOAuthService {
    private func formBody(_ params: [String: String]) -> Data {
        let comps = params.map { key, val in
            "\(key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
            + "="
            + "\(val.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        }.joined(separator: "&")
        return comps.data(using: .utf8)!
    }

    private func decodeError(_ data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8) ?? "Unknown error"
        }
        return (json["error_description"] as? String)
            ?? (json["error"] as? String)
            ?? "Unknown error"
    }

    private func exchangeCode(code: String, verifier: String, redirectURI: String) async throws -> String {
        let body = formBody([
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code",
            "code_verifier": verifier,
        ])
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (data, _) = try await URLSession.shared.data(for: req)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw OAuthError.tokenFailed(decodeError(data))
        }

        let expiresIn = json["expires_in"] as? TimeInterval ?? 3600
        let token = Token(accessToken: accessToken, expiryDate: Date().addingTimeInterval(expiresIn))
        saveToken(token)

        if let refreshToken = json["refresh_token"] as? String {
            saveRefreshToken(refreshToken)
        }

        return accessToken
    }

    private func refreshAccessToken(refreshToken: String) async throws -> Token {
        let body = formBody([
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ])
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (data, _) = try await URLSession.shared.data(for: req)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw OAuthError.tokenFailed(decodeError(data))
        }
        let expiresIn = json["expires_in"] as? TimeInterval ?? 3600
        return Token(accessToken: accessToken, expiryDate: Date().addingTimeInterval(expiresIn))
    }
}

// MARK: - Models

private struct Token: Codable {
    let accessToken: String
    let expiryDate: Date
    var isExpired: Bool { Date() >= expiryDate }
}

private struct RefreshToken: Codable {
    let value: String
}

enum OAuthError: Error, LocalizedError {
    case notConnected
    case timeout
    case serverFailed
    case tokenFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to Google"
        case .timeout: return "Authorization timed out"
        case .serverFailed: return "Failed to start callback server"
        case .tokenFailed(let m): return m
        }
    }
}

// MARK: - PKCE

private func genVerifier() -> String {
    var b = [UInt8](repeating: 0, count: 64)
    _ = SecRandomCopyBytes(kSecRandomDefault, b.count, &b)
    return b.map { String(format: "%02x", $0) }.joined()
}

private func sha256(_ d: Data) -> Data {
    var h = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    d.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(d.count), &h) }
    return Data(h)
}

private func b64url(_ d: Data) -> String {
    d.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}
