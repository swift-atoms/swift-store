public import Store

@_documentation(visibility: public)
public protocol __StoreDirectProtocol: __StoreProtocol, ~Copyable {

    associatedtype Bounded: ~Copyable
}

extension Store::Store {

    public typealias Direct = __StoreDirectProtocol
}
