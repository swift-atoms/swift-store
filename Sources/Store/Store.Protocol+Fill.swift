public import Cardinal
import Difference
public import Index
public import Ordinal
public import Tagged

extension __StoreProtocol where Self: ~Copyable, Element: Copyable {

    @inlinable
    public mutating func fill(range: Swift.Range<Index<Element>>, with element: borrowing Element) {
        var slot = range.lowerBound
        while slot < range.upperBound {
            initialize(at: slot, to: copy element)
            slot += .one
        }
    }
}

extension __StoreLedgeredProtocol where Self: ~Copyable, Element: Copyable {

    @inlinable
    public mutating func fill(with element: borrowing Element) {
        precondition(initialization.isEmpty, "Store.fill(with:): the store must be vacant")
        let upper: Index<Element> = capacity.map(Ordinal.init)
        fill(range: .zero..<upper, with: element)
        initialization = .linear(count: capacity)
    }
}
