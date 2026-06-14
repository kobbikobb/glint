import Foundation

protocol ItemStore {
    func saveItems(_ items: [Item]) throws
    func items(for date: Date) throws -> [Item]
    func deleteItems(before date: Date) throws
}
