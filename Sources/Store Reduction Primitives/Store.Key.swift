extension Store {

    public enum Key {}
}

extension Store.Key {

    public typealias `Protocol` = __StoreKeyProtocol

    public typealias Aggregate = __StoreKeyAggregateProtocol
}
