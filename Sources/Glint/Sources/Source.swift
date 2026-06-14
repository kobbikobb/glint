import Foundation

protocol Source {
    var id: String { get }
    func fetch() async throws -> [Item]
}
