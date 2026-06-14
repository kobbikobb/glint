import Foundation

protocol ConfigStore {
    func saveSourceConfig(_ config: SourceConfig) throws
    func sourceConfigs() throws -> [SourceConfig]
    func deleteSourceConfig(id: String) throws
}
