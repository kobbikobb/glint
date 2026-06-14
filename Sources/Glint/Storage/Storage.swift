import Foundation

protocol Storage {
    func saveItems(_ items: [Item]) throws
    func items(for date: Date) throws -> [Item]
    func deleteItems(before date: Date) throws

    func saveSourceConfig(_ config: SourceConfig) throws
    func sourceConfigs() throws -> [SourceConfig]
    func deleteSourceConfig(id: String) throws
}
