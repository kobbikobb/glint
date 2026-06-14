import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            mainView
        } else {
            OnboardingView(isComplete: $onboardingDone)
        }
    }

    private var mainView: some View {
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
}
