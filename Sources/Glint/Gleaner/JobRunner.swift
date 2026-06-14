import Foundation

actor JobRunner {
    private let storage: Storage
    private var sources: [String: Source] = [:]

    init(storage: Storage) {
        self.storage = storage
    }

    func register(_ source: Source) {
        sources[source.id] = source
    }

    func runAll() async {
        let configs: [SourceConfig]
        do {
            configs = try storage.sourceConfigs()
        } catch {
            return
        }

        for config in configs where config.isEnabled {
            guard let source = sources[config.id] else { continue }
            do {
                let items = try await source.fetch()
                try storage.saveItems(items)
            } catch {

            }
        }
    }
}
