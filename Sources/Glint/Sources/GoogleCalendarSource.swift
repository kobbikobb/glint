import Foundation

struct GoogleCalendarSource: Source {
    let id = "google_calendar"
    private let oauth = GoogleOAuthService()

    func fetch() async throws -> [Item] {
        let token = try await oauth.getAccessToken()
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        let tmin = fmt.string(from: Date().startOfDay)
        let tmax = fmt.string(from: Date().startOfDay.addingTimeInterval(86400 * 7))
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events?timeMin=\(tmin)&timeMax=\(tmax)&singleEvents=true&orderBy=startTime")!

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw SourceError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            return []
        }

        return items.compactMap { event in
            guard let title = event["summary"] as? String,
                  let id = event["id"] as? String else { return nil }

            let startStr = (event["start"] as? [String: Any])?["dateTime"] as? String
                ?? (event["start"] as? [String: Any])?["date"] as? String ?? ""
            let date = fmt.date(from: startStr)
                ?? {
                    let dFmt = DateFormatter()
                    dFmt.dateFormat = "yyyy-MM-dd"
                    return dFmt.date(from: startStr)
                }() ?? Date()

            let desc = event["description"] as? String

            return Item(
                id: id,
                sourceId: self.id,
                title: title,
                summary: desc,
                date: date,
                url: nil,
                urgency: .unclassified
            )
        }
    }
}

enum SourceError: Error, LocalizedError {
    case apiError
    var errorDescription: String? { "Google Calendar API error" }
}

private extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
