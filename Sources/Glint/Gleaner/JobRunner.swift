import Foundation

actor JobRunner {
    private let itemStore: ItemStore
    private let configStore: ConfigStore
    private var sources: [String: Source] = [:]

    init(itemStore: ItemStore, configStore: ConfigStore) {
        self.itemStore = itemStore
        self.configStore = configStore
    }

    func register(_ source: Source) {
        sources[source.id] = source
    }

    func runAll() async {
        let configs: [SourceConfig]
        do {
            configs = try configStore.sourceConfigs()
        } catch {
            return
        }

        for config in configs where config.isEnabled {
            guard let source = sources[config.id] else { continue }
            do {
                let items = try await source.fetch()
                try itemStore.saveItems(items)
            } catch {

            }
        }
    }
}
