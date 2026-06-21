import SwiftUI

struct PreferencesView: View {
    var body: some View {
        Form {
            Section("Sources") {
                Text("Sources will be available in upcoming slices.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 400, height: 200)
    }
}
