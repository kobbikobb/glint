import Factory

extension Container {
    var itemStore: Factory<ItemStore> { self { UserDefaultsItemStore() }.singleton }
    var configStore: Factory<ConfigStore> { self { UserDefaultsConfigStore() }.singleton }
    var jobRunner: Factory<JobRunner> { self { JobRunner(itemStore: self.itemStore(), configStore: self.configStore()) }.singleton }
    var scheduler: Factory<Scheduler> { self { Scheduler(jobRunner: self.jobRunner()) }.singleton }
}
