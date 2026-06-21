import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var step = 0
    @AppStorage("triggerHour") private var triggerHour = 8
    @AppStorage("triggerMinute") private var triggerMinute = 0

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if step == 0 { welcomeStep }
                else if step == 1 { connectStep }
                else if step == 2 { scheduleStep }
                else { doneStep }
            }

            Divider()

            HStack {
                if step > 0 && step < 3 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if step < 3 {
                    Button("Continue") { step += 1 }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 480, height: 380)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sun.max")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Welcome to Glint")
                .font(.largeTitle)
                .bold()
            Text("Every morning, Glint gathers the highlights from your calendar, email, and social feeds — so you start your day knowing what matters.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    private var connectStep: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "link")
                .font(.system(size: 36))
                .foregroundStyle(.blue)
            Text("Connect your sources")
                .font(.title2)
                .bold()
            Text("Glint works with Google Calendar, Outlook, and Gmail. You can add them anytime in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            HStack(spacing: 12) {
                ForEach(["Google", "Outlook", "Gmail"], id: \.self) { name in
                    VStack(spacing: 4) {
                        Image(systemName: icon(for: name))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 70, height: 60)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))
                }
            }
            .padding(.top, 4)
            Spacer()
        }
        .padding()
    }

    private var scheduleStep: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 36))
                .foregroundStyle(.green)
            Text("When should Glint appear?")
                .font(.title2)
                .bold()
            Text("Glint will show your daily summary shortly after you wake up.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            HStack {
                Picker("Hour", selection: $triggerHour) {
                    ForEach(5..<12) { Text("\($0)").tag($0) }
                }
                .frame(width: 70)
                Text(":")
                Picker("Minute", selection: $triggerMinute) {
                    ForEach([0, 15, 30, 45], id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }
                .frame(width: 70)
            }
            .pickerStyle(.menu)
            Spacer()
        }
        .padding()
    }

    private var doneStep: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("You're all set")
                .font(.largeTitle)
                .bold()
            Text("Glint will greet you tomorrow morning with your personal briefing. Open the menu bar icon anytime to adjust settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button("Done") {
                isComplete = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .padding()
    }

    private func icon(for source: String) -> String {
        switch source {
        case "Google": "calendar"
        case "Outlook": "envelope"
        case "Gmail": "envelope.fill"
        default: "questionmark"
        }
    }
}
