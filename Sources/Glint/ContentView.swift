import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var onboardingDone = false
    let digest: DigestService

    @State private var items: [Item] = []

    var body: some View {
        Group {
            if onboardingDone {
                if items.isEmpty {
                    welcomeView
                } else {
                    itemsListView
                }
            } else {
                OnboardingView(isComplete: $onboardingDone)
            }
        }
        .task {
            if onboardingDone {
                items = digest.loadToday()
            }
        }
    }

    private var welcomeView: some View {
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

            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(40)
        .frame(width: 420, height: 320)
    }

    private var itemsListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("Good morning ☀️")
                    .font(.title)
                    .bold()

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        if let summary = item.summary {
                            Text(summary)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 420, height: 500)
    }
}
