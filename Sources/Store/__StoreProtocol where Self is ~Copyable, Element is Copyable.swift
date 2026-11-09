public import Cardinal
import Difference
public import Index
public import Ordinal
public import Tagged

extension __StoreProtocol where Self: ~Copyable, Element: Copyable {

    @inlinable
    public func copy<Destination: __StoreProtocol & ~Copyable>(
        to destination: inout Destination,
        count: Index<Element>.Count
    ) where Destination.Element == Element {

        var slot: Index<Element> = .zero
        let upper: Index<Element> = count.map(Ordinal.init)
        while slot < upper {
            destination.initialize(at: slot, to: self[slot])
            slot += .one
        }
    }
}

extension __StoreLedgeredProtocol where Self: ~Copyable, Element: Copyable {

    @inlinable
    public func copy<Destination: __StoreProtocol & ~Copyable>(
        to destination: inout Destination
    ) where Destination.Element == Element {

        initialization.forEach { range in
            var slot = range.lowerBound
            while slot < range.upperBound {
                destination.initialize(at: slot, to: self[slot])
                slot += .one
            }
        }
    }
}
