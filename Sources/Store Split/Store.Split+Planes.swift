public import Store
public import Store_Protocol

extension Store::Store.Split where Lanes: ~Copyable, Elements: ~Copyable {

    @inlinable
    public var lanes: Lanes {
        _read { yield _lanes }
        _modify { yield &_lanes }
    }

    @inlinable
    public var elements: Elements {
        _read { yield _elements }
        _modify { yield &_elements }
    }
}

extension Store::Store.Split where Lanes: ~Copyable, Elements: ~Copyable {

    @inlinable
    public func withLanes<R, Failure: Swift.Error>(
        _ body: (borrowing Lanes) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(_lanes)
    }

    @inlinable
    public mutating func withMutableLanes<R, Failure: Swift.Error>(
        _ body: (inout Lanes) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&_lanes)
    }

    @inlinable
    public func withElements<R, Failure: Swift.Error>(
        _ body: (borrowing Elements) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(_elements)
    }

    @inlinable
    public mutating func withMutableElements<R, Failure: Swift.Error>(
        _ body: (inout Elements) throws(Failure) -> R
    ) throws(Failure) -> R {
        try body(&_elements)
    }
}
