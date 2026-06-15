import Foundation

struct DigestService {
    private let itemStore: ItemStore
    private let classifier: Classifier

    init(itemStore: ItemStore, classifier: Classifier) {
        self.itemStore = itemStore
        self.classifier = classifier
    }

    func loadToday() async -> [Item] {
        let items = (try? itemStore.items(for: Date())) ?? []
        return await classifier.classify(items)
    }
}
