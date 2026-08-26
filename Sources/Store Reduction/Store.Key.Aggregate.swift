public import Algebra_Monoid

public protocol __StoreKeyAggregateProtocol: __StoreKeyProtocol {

    static var aggregation: Algebra.Monoid<Value> { get }
}

extension __StoreKeyAggregateProtocol {

    public static var initial: Value {
        aggregation.identity
    }
}
