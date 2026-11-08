public import Cardinal
import Difference
public import Index
public import Ordinal
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

extension __StoreProtocol where Self: ~Copyable {

    @inlinable
    public mutating func move(from source: Index<Element>, to destination: Index<Element>) {
        guard source != destination else { return }
        initialize(at: destination, to: move(at: source))
    }

    @inlinable
    public mutating func moveInitialize(
        from source: Index<Element>,
        to destination: Index<Element>,
        count: Index<Element>.Count
    ) {
        guard count > .zero, source != destination else { return }
        if destination > source {

            var remaining: Index<Element>.Count = count
            while remaining > .zero {
                let step: Index<Element>.Count = remaining.subtract.saturating(.one)
                let offset = Index<Element>.Offset(fromZero: step.map(Ordinal.init))

                do {
                    let sourceSlot = try source + offset
                    let destinationSlot = try destination + offset
                    move(from: sourceSlot, to: destinationSlot)
                } catch {
                    preconditionFailure("Offset derived from a count within the source and destination ranges: \(error)")
                }
                remaining = step
            }
        } else {

            var sourceSlot = source
            var destinationSlot = destination
            var step: Index<Element>.Count = .zero
            while step < count {
                move(from: sourceSlot, to: destinationSlot)
                sourceSlot += .one
                destinationSlot += .one
                step = step.add.saturating(.one)
            }
        }
    }
}
