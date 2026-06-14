import Foundation

final class UserDefaultsStorage: Storage {
    private let defaults: UserDefaults

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
            if key.hasPrefix(itemsPrefix) {
                defaults.removeObject(forKey: key)
            }
        }
    }

    func saveSourceConfig(_ config: SourceConfig) throws {
        var configs = try sourceConfigs()
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
        let data = try JSONEncoder().encode(configs)
        defaults.set(data, forKey: sourceConfigsKey)
    }

    func sourceConfigs() throws -> [SourceConfig] {
        guard let data = defaults.data(forKey: sourceConfigsKey) else { return [] }
        return try JSONDecoder().decode([SourceConfig].self, from: data)
    }

    func deleteSourceConfig(id: String) throws {
        var configs = try sourceConfigs()
        configs.removeAll { $0.id == id }
        let data = try JSONEncoder().encode(configs)
        defaults.set(data, forKey: sourceConfigsKey)
    }

    private let itemsPrefix = "glint_items_"
    private let sourceConfigsKey = "glint_sourceConfigs"

    private func itemsKey(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return "\(itemsPrefix)\(formatter.string(from: date))"
    }
}
