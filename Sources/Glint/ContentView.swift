import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sun.max")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Welcome to Glint")
                .font(.largeTitle)
                .bold()

            Text("Your morning briefing, distilled from calendar, email, and social.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Button("Get Started") {
                // TODO: Open preferences
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(40)
        .frame(width: 420, height: 320)
    }
}
