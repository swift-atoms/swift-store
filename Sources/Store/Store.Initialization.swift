public import Cardinal
public import Index
public import Ordinal
public import Tagged

extension Store::Store {

    public enum Initialization<Element: ~Copyable & ~Escapable>: Sendable, Equatable {

        case empty

        case one(Swift.Range<Index::Index<Element>>)

        case two(
            first: Swift.Range<Index::Index<Element>>,
            second: Swift.Range<Index::Index<Element>>
        )
    }
}

extension Store::Store.Initialization where Element: ~Copyable & ~Escapable {

    @inlinable
    public var count: Index::Index<Element>.Count {
        switch self {
        case .empty:
            return .zero

        case .one(let span):
            return span.count

        case .two(let first, let second):
            return first.count + second.count
        }
    }

    @inlinable
    public var isEmpty: Bool {
        switch self {
        case .empty:
            return true

        case .one(let span):
            return span.isEmpty

        case .two(let first, let second):
            return first.isEmpty && second.isEmpty
        }
    }
}

extension Store::Store.Initialization where Element: ~Copyable & ~Escapable {

    @inlinable
    public var isPrefixShaped: Bool {
        switch self {
        case .empty:
            return true

        case .one(let range):
            return range.lowerBound == .zero

        case .two:
            return false
        }
    }
}

extension Store::Store.Initialization where Element: ~Copyable & ~Escapable {

    @inlinable
    public func forEach<E: Swift.Error>(
        _ body: (Swift.Range<Index<Element>>) throws(E) -> Void
    ) throws(E) {
        switch self {
        case .empty: break
        case .one(let range): try body(range)

        case .two(let first, let second):
            try body(first)
            try body(second)
        }
    }
}

extension Store::Store.Initialization where Element: ~Copyable & ~Escapable {

    @inlinable
    public func linearize(
        _ body: (Swift.Range<Index<Element>>, _ offset: Index<Element>) -> Void
    ) {
        var offset: Index<Element> = .zero
        forEach { range in
            body(range, offset)
            offset += range.count
        }
    }
}

extension Store::Store.Initialization where Element: ~Copyable & ~Escapable {

    @inlinable
    public static func linear(count: Index<Element>.Count) -> Self {
        guard count > .zero else { return .empty }
        return .one(Swift.Range<Index<Element>>(start: .zero, count: count))
    }
}

extension Store::Store.Initialization where Element: ~Copyable & ~Escapable {

    @inlinable
    public func contains(_ slot: Index<Element>) -> Bool {
        switch self {
        case .empty:
            return false

        case .one(let range):
            return range.contains(slot)

        case .two(let first, let second):
            return first.contains(slot) || second.contains(slot)
        }
    }
}

extension Store::Store.Initialization where Element: ~Copyable & ~Escapable {

    @inlinable
    package static func _normalized(
        _ first: Swift.Range<Index<Element>>,
        _ second: Swift.Range<Index<Element>>
    ) -> Self {
        if first.isEmpty { return second.isEmpty ? .empty : .one(second) }
        if second.isEmpty { return .one(first) }
        if first.upperBound == second.lowerBound { return .one(first.lowerBound..<second.upperBound) }
        if second.upperBound == first.lowerBound { return .one(second.lowerBound..<first.upperBound) }
        return .two(first: first, second: second)
    }

    @inlinable
    package static func _extending(
        _ range: Swift.Range<Index<Element>>,
        with slot: Index<Element>
    ) -> Swift.Range<Index<Element>>? {
        let next = Swift.Range<Index<Element>>(start: slot, count: .one).upperBound
        if slot == range.upperBound { return range.lowerBound..<next }
        if next == range.lowerBound { return slot..<range.upperBound }
        return nil
    }

    /// The ledger after `slot` becomes initialized.
    ///
    /// - Precondition: `slot` is vacant, and the result is at most two ranges.
    @inlinable
    public func inserting(_ slot: Index<Element>) -> Self {
        precondition(!contains(slot), "Store.Initialization.inserting(_:): slot is already initialized")
        let single = Swift.Range<Index<Element>>(start: slot, count: .one)
        switch self {
        case .empty:
            return .one(single)

        case .one(let range):
            if range.isEmpty { return .one(single) }
            if let extended = Self._extending(range, with: slot) { return .one(extended) }
            return slot > range.lowerBound
                ? .two(first: single, second: range)
                : .two(first: range, second: single)

        case .two(let first, let second):
            if first.isEmpty { return Self.one(second).inserting(slot) }
            if second.isEmpty { return Self.one(first).inserting(slot) }
            if let extended = Self._extending(first, with: slot) { return Self._normalized(extended, second) }
            if let extended = Self._extending(second, with: slot) { return Self._normalized(first, extended) }
            preconditionFailure(
                "Store.Initialization.inserting(_:): initializing this slot needs a third range"
            )
        }
    }

    /// The ledger after `slot` becomes vacant.
    ///
    /// - Precondition: `slot` is initialized, and the result is at most two ranges.
    @inlinable
    public func removing(_ slot: Index<Element>) -> Self {
        precondition(contains(slot), "Store.Initialization.removing(_:): slot is not initialized")
        let next = Swift.Range<Index<Element>>(start: slot, count: .one).upperBound
        switch self {
        case .empty:
            preconditionFailure("Store.Initialization.removing(_:): slot is not initialized")

        case .one(let range):
            return Self._normalized(range.lowerBound..<slot, next..<range.upperBound)

        case .two(let first, let second):
            let split = first.contains(slot) ? first : second
            let other = first.contains(slot) ? second : first
            let below = split.lowerBound..<slot
            let above = next..<split.upperBound
            precondition(
                below.isEmpty || above.isEmpty || other.isEmpty,
                "Store.Initialization.removing(_:): vacating this slot needs a third range"
            )
            if other.isEmpty { return Self._normalized(below, above) }
            let remaining = below.isEmpty ? above : below
            return first.contains(slot)
                ? Self._normalized(remaining, other)
                : Self._normalized(other, remaining)
        }
    }
}
