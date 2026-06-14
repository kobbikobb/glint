import Foundation

struct DigestService {
    private let itemStore: ItemStore

    init(itemStore: ItemStore) {
        self.itemStore = itemStore
    }

    func loadToday() -> [Item] {
        (try? itemStore.items(for: Date())) ?? []
    }
}
