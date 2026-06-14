import AppKit

class Scheduler {
    private let jobRunner: JobRunner
    private let calendar: Calendar
    private let userDefaults: UserDefaults

    init(jobRunner: JobRunner, calendar: Calendar = .current, userDefaults: UserDefaults = .standard) {
        self.jobRunner = jobRunner
        self.calendar = calendar
        self.userDefaults = userDefaults
    }

    @objc func screenDidWakeUp() -> Bool {
        digest(now: Date())
    }

    func digest(now: Date = Date()) -> Bool {
        guard isMorning(now: now) && !hasRunToday(now: now) else { return false }

        Task {
            await jobRunner.runAll()
        }

        setHasRunToday(now: now)
        return true
    }

    private func isMorning(now: Date) -> Bool {
        let start = 60 * 5
        let end = 60 * 11
        let minutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        return (start...end).contains(minutes)
    }

    private func hasRunToday(now: Date) -> Bool {
        let today = calendar.startOfDay(for: now)
        guard let last = userDefaults.object(forKey: "lastGlintDate") as? Date else { return false }
        return calendar.isDate(last, inSameDayAs: today)
    }

    private func setHasRunToday(now: Date) {
        userDefaults.set(now, forKey: "lastGlintDate")
    }
}
