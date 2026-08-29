public import Index
public import Ordinal_Protocol
public import Store
public import Store_Protocol

extension Store::Store.Split where Lanes: ~Copyable, Elements: ~Copyable {

    @inlinable
    public var capacity: Index<Elements.Element>.Count {
        _elements.capacity
    }

    @inlinable
    public subscript(slot: Index<Elements.Element>) -> Elements.Element {
        _read { yield _elements[slot] }
        _modify { yield &_elements[slot] }
    }

    @inlinable
    public mutating func initialize(
        at slot: Index<Elements.Element>,
        to element: consuming Elements.Element
    ) {
        _elements.initialize(at: slot, to: element)
    }

    @inlinable
    public mutating func move(at slot: Index<Elements.Element>) -> Elements.Element {
        _elements.move(at: slot)
    }
}

extension Store::Store.Split: Store::Store.`Protocol`
where Lanes: ~Copyable, Elements: ~Copyable {}
