public import Cardinal
import Difference
public import Index
public import Ordinal
public import Tagged

extension __StoreLedgeredProtocol where Self: ~Copyable {

    @inlinable
    public func forEach<E: Swift.Error>(
        _ body: (borrowing Element) throws(E) -> Void
    ) throws(E) {
        try initialization.forEach { (range: Swift.Range<Index<Element>>) throws(E) in
            var slot = range.lowerBound
            while slot < range.upperBound {
                try body(self[slot])
                slot += .one
            }
        }
    }

    @inlinable
    public func reduce<Result, E: Swift.Error>(
        into initialResult: consuming Result,
        _ accumulate: (inout Result, borrowing Element) throws(E) -> Void
    ) throws(E) -> Result {
        var result = initialResult
        try forEach { (element: borrowing Element) throws(E) in
            try accumulate(&result, element)
        }
        return result
    }

    @inlinable
    public func contains<E: Swift.Error>(
        where predicate: (borrowing Element) throws(E) -> Bool
    ) throws(E) -> Bool {
        var found = false
        try initialization.forEach { (range: Swift.Range<Index<Element>>) throws(E) in
            var slot = range.lowerBound
            while !found, slot < range.upperBound {
                found = try predicate(self[slot])
                slot += .one
            }
        }
        return found
    }
}

extension __StoreLedgeredProtocol where Self: ~Copyable, Element: Equatable {

    @inlinable
    public func contains(_ element: borrowing Element) -> Bool {
        contains { $0 == element }
    }
}
