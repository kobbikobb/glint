import SwiftUI
import Factory

struct PreferencesView: View {
    @StateObject private var model = PreferencesViewModel()

    var body: some View {
        Form {
            Section("Sources") {
                HStack {
                    Label("Google Calendar", systemImage: "calendar")
                    Spacer()
                    if model.isConnecting || model.isTesting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button(model.isConnected ? "Disconnect" : "Connect") {
                            Task { await model.toggle() }
                        }
                    }
                }
                if model.isConnected {
                    Button("Test Token") {
                        Task { await model.testToken() }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .disabled(model.isTesting)
                }
                if let status = model.statusText {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(width: 400, height: 200)
        .onAppear { model.refresh() }
        .alert("Error", isPresented: $model.showError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage)
        }
    }
}

@MainActor
private class PreferencesViewModel: ObservableObject {
    @Injected(\.googleOAuth) private var oauth
    @Injected(\.configStore) private var configStore
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var isTesting = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var statusText: String?

    func refresh() {
        isConnected = oauth.isConnected
    }

    func toggle() async {
        isConnecting = true
        statusText = nil
        if isConnected {
            oauth.disconnect()
            try? configStore.deleteSourceConfig(id: "google_calendar")
            isConnected = false
        } else {
            do {
                let _ = try await oauth.connect()
                let config = SourceConfig(
                    id: "google_calendar",
                    isEnabled: true,
                    authState: .connected,
                    displayName: "Google Calendar",
                    filterGroups: [],
                    excludePatterns: []
                )
                try configStore.saveSourceConfig(config)

                let source = GoogleCalendarSource()
                let items = try await source.fetch()
                statusText = "\(items.count) events found for next 7 days"
                isConnected = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        isConnecting = false
    }

    func testToken() async {
        isTesting = true
        statusText = nil
        do {
            let token = try await oauth.getAccessToken()
            statusText = "Token OK (\(token.prefix(10))…)"
        } catch {
            statusText = "Token failed: \(error.localizedDescription)"
        }
        isTesting = false
    }
}
