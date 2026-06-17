import Factory

extension Container {
    var itemStore: Factory<ItemStore> { self { UserDefaultsItemStore() }.singleton }
    var configStore: Factory<ConfigStore> { self { UserDefaultsConfigStore() }.singleton }
    var jobRunner: Factory<JobRunner> { self { JobRunner(itemStore: self.itemStore(), configStore: self.configStore()) }.singleton }
    var scheduler: Factory<Scheduler> { self { Scheduler(jobRunner: self.jobRunner()) }.singleton }
    var classifier: Factory<Classifier> { self { NoopClassifier() }.singleton }
    var digestService: Factory<DigestService> { self { DigestService(itemStore: self.itemStore(), classifier: self.classifier()) }.singleton }

    private static let facebookAppId = "3056160937912400"

    var facebookOAuth: Factory<FacebookOAuthService> {
        self { FacebookOAuthService(appId: Self.facebookAppId, configStore: self.configStore()) }.singleton
    }
}
