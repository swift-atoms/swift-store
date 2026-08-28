public import Store_Initialization
public import Store
public import Store_Protocol

public protocol __StoreLedgeredProtocol: Store::Store.`Protocol`, ~Copyable {

    var initialization: Store::Store.Initialization<Element> { get set }
}

extension Store::Store {

    public enum Ledgered {}
}

extension Store::Store.Ledgered {

    public typealias `Protocol` = __StoreLedgeredProtocol
}
