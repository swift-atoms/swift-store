extension Store::Store {

    @frozen
    public struct Split<
        Lanes: Store::Store.`Protocol` & ~Copyable,
        Elements: Store::Store.`Protocol` & ~Copyable
    >: ~Copyable {

        @usableFromInline
        internal var _lanes: Lanes

        @usableFromInline
        internal var _elements: Elements

        @inlinable
        public init(lanes: consuming Lanes, elements: consuming Elements) {
            self._lanes = lanes
            self._elements = elements
        }
    }
}

extension Store::Store.Split where Lanes: ~Copyable, Elements: ~Copyable {

    public typealias Element = Elements.Element

    public typealias Lane = Lanes.Element
}

extension Store::Store.Split: Swift.Copyable where Lanes: Swift.Copyable, Elements: Swift.Copyable {}

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
