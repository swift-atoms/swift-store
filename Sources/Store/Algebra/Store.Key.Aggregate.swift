#if Algebra
public import Algebra

public protocol __StoreKeyAggregateProtocol: __StoreKeyProtocol {

    static var aggregation: Algebra.Monoid<Value> { get }
}

extension __StoreKeyAggregateProtocol {

    public static var initial: Value {
        aggregation.identity
    }
}

extension Store::Store.Key {

    public typealias Aggregate = __StoreKeyAggregateProtocol
}
#endif
