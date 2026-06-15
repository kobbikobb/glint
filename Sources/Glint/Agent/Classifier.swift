import Foundation

protocol Classifier {
    func classify(_ items: [Item]) async -> [Item]
}
