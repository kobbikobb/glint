import Foundation

final class UserDefaultsConfigStore: ConfigStore {
    private let defaults: UserDefaults
    private let key = "glint_sourceConfigs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveSourceConfig(_ config: SourceConfig) throws {
        var configs = try sourceConfigs()
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
        let data = try JSONEncoder().encode(configs)
        defaults.set(data, forKey: key)
    }

    func sourceConfigs() throws -> [SourceConfig] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([SourceConfig].self, from: data)
    }

    func deleteSourceConfig(id: String) throws {
        var configs = try sourceConfigs()
        configs.removeAll { $0.id == id }
        let data = try JSONEncoder().encode(configs)
        defaults.set(data, forKey: key)
    }
}
