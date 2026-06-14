@testable import Glint
import XCTest

final class GlintTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }

    func testJobRunnerRunsSourcesAndSavesItems() async throws {
        let itemStore = MockItemStore()
        let configStore = MockConfigStore()
        let source = MockSource(id: "fb", items: [
            Item(id: "1", sourceId: "fb", title: "Event", summary: nil, date: Date(), url: nil, urgency: .unclassified),
        ])

        let runner = JobRunner(itemStore: itemStore, configStore: configStore)
        await runner.register(source)
        try configStore.saveSourceConfig(.init(id: "fb", isEnabled: true, authState: .connected, displayName: "FB", filterGroups: [], excludePatterns: []))

        await runner.runAll()

        let saved = try itemStore.items(for: Date())
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].id, "1")
    }

    func testJobRunnerSkipsDisabledSources() async throws {
        let itemStore = MockItemStore()
        let configStore = MockConfigStore()
        let source = MockSource(id: "fb", items: [
            Item(id: "1", sourceId: "fb", title: "Event", summary: nil, date: Date(), url: nil, urgency: .unclassified),
        ])

        let runner = JobRunner(itemStore: itemStore, configStore: configStore)
        await runner.register(source)
        try configStore.saveSourceConfig(.init(id: "fb", isEnabled: false, authState: .connected, displayName: "FB", filterGroups: [], excludePatterns: []))

        await runner.runAll()

        let saved = try itemStore.items(for: Date())
        XCTAssertTrue(saved.isEmpty)
    }
}

private class MockItemStore: ItemStore {
    var items: [String: [Item]] = [:]

    func saveItems(_ items: [Item]) throws {
        let key = itemsKey(for: items.first?.date ?? Date())
        self.items[key] = items
    }

    func items(for date: Date) throws -> [Item] {
        let key = itemsKey(for: date)
        return items[key] ?? []
    }

    func deleteItems(before date: Date) throws {
        items.removeAll()
    }

    private func itemsKey(for date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}

private class MockConfigStore: ConfigStore {
    var configs: [SourceConfig] = []

    func saveSourceConfig(_ config: SourceConfig) throws {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
    }

    func sourceConfigs() throws -> [SourceConfig] {
        configs
    }

    func deleteSourceConfig(id: String) throws {
        configs.removeAll { $0.id == id }
    }
}

private class MockSource: Source {
    let id: String
    private let result: [Item]

    init(id: String, items: [Item]) {
        self.id = id
        self.result = items
    }

    func fetch() async throws -> [Item] {
        result
    }
}
