public import Index
public import Difference
public import Cardinal
public import Ordinal
public import Ordinal_Standard_Library_Integration
public import Tagged

extension __StoreProtocol where Self: ~Copyable {

    @inlinable
    public mutating func deinitialize(at slot: Index<Element>) {
        _ = move(at: slot)
    }

    @inlinable
    public mutating func deinitialize(range: Swift.Range<Index<Element>>) {
        var slot = range.lowerBound
        while slot < range.upperBound {
            _ = move(at: slot)
            slot += .one
        }
    }

    @inlinable
    public mutating func clear() {
        let upper: Index<Element> = capacity.map(Ordinal.init)
        deinitialize(range: .zero..<upper)
    }

    @inlinable
    public mutating func removeAll() {
        clear()
    }
}
