import Foundation

final class UserDefaultsItemStore: ItemStore {
    private let defaults: UserDefaults
    private let prefix = "glint_items_"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveItems(_ items: [Item]) throws {
        let key = itemsKey(for: items.first?.date ?? Date())
        let data = try JSONEncoder().encode(items)
        defaults.set(data, forKey: key)
    }

    func items(for date: Date) throws -> [Item] {
        let key = itemsKey(for: date)
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([Item].self, from: data)
    }

    func deleteItems(before date: Date) throws {
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix(prefix) {
                defaults.removeObject(forKey: key)
            }
        }
    }

    private func itemsKey(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return "\(prefix)\(formatter.string(from: date))"
    }
}
