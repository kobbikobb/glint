import AppKit

class Scheduler {

    private let jobRunner: JobRunner 
   
    init(jobRunner: JobRunner) {
        self.jobRunner = jobRunner
    }

    @objc func screenDidWakeUp() -> Bool {
        guard (isMorning() && !hasRunToday()) else { return false}

        Task {
            await jobRunner.runAll()
        }
       
        setHasRunToday()

        return true
    }

    @objc private func isMorning() -> Bool {
        let startOfMorningMinutesFromMidnight = 60 * 5
        let endOfMorningMinutesFromMidnight = 60 * 11

        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentMinutesFromMidnite = currentHour * 60 + Calendar.current.component(.minute, from: Date())

        return (startOfMorningMinutesFromMidnight...endOfMorningMinutesFromMidnight).contains(currentMinutesFromMidnite)
    }

    @objc private func hasRunToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = UserDefaults.standard.object(forKey: "lastGlintDate") as? Date,
           Calendar.current.isDate(last, inSameDayAs: today) {
            return true
        }
        return false
    }

    @objc private func setHasRunToday() {
        UserDefaults.standard.set(Date(), forKey: "lastGlintDate")
    }
}
