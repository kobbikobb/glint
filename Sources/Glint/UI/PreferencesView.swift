import SwiftUI
import Factory

struct PreferencesView: View {
    @StateObject private var model = PreferencesViewModel()

    var body: some View {
        Form {
            Section("Sources") {
                HStack {
                    Label("Facebook", systemImage: "f.circle")
                    Spacer()
                    Button(model.isConnected ? "Disconnect" : "Connect") {
                        Task { await model.toggle() }
                    }
                    .disabled(model.isBusy)
                }
            }
        }
        .padding(20)
        .frame(width: 400, height: 200)
        .onAppear { model.refresh() }
        .alert("OAuth Error", isPresented: $model.showError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage)
        }
    }
}

@MainActor
private class PreferencesViewModel: ObservableObject {
    @Injected(\.facebookOAuth) private var oauth
    @Published var isConnected = false
    @Published var isBusy = false
    @Published var showError = false
    @Published var errorMessage = ""

    func refresh() {
        isConnected = oauth.isConnected
    }

    func toggle() async {
        isBusy = true
        if isConnected {
            try? oauth.disconnect()
            isConnected = false
        } else {
            do {
                try await oauth.connect()
                isConnected = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        isBusy = false
    }
}
