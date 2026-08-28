public import Store
public import Store_Protocol

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

extension Store::Store.Split: Copyable where Lanes: Copyable, Elements: Copyable {}
