import Foundation

enum Urgency: String, Codable, CaseIterable, Comparable {
    case unclassified
    case noise
    case important
    case urgent

    private var rank: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    static func < (lhs: Urgency, rhs: Urgency) -> Bool {
        lhs.rank < rhs.rank
    }
}

struct Item: Codable, Identifiable, Equatable {
    let id: String
    let sourceId: String
    let title: String
    let summary: String?
    let date: Date
    let url: URL?
    var urgency: Urgency
}
