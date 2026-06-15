import Foundation

struct NoopClassifier: Classifier {
    func classify(_ items: [Item]) async -> [Item] {
        items
    }
}
