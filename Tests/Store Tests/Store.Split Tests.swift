import Store
import Testing

private struct TailStore: Store.`Protocol`, ~Copyable {
    var values: [Int]
    var swapCalls = 0
    var moveCalls = 0
    var initializeCalls = 0
    var unshareCalls = 0

    var capacity: Index<Int>.Count { 4 }

    subscript(slot: Index<Int>) -> Int {
        get { values[Int(slot.underlying.rawValue)] }
        set { values[Int(slot.underlying.rawValue)] = newValue }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        precondition(Int(slot.underlying.rawValue) == values.count)
        precondition(values.count < 4)
        initializeCalls += 1
        values.append(element)
    }

    mutating func move(at slot: Index<Int>) -> Int {
        precondition(Int(slot.underlying.rawValue) == values.count - 1)
        moveCalls += 1
        return values.removeLast()
    }

    mutating func swapAt(_ i: Index<Int>, _ j: Index<Int>) {
        swapCalls += 1
        values.swapAt(Int(i.underlying.rawValue), Int(j.underlying.rawValue))
    }

    mutating func unshare() { unshareCalls += 1 }
}

private func swap<S: Store.`Protocol` & ~Copyable>(
    _ store: inout S,
    _ i: Index<Int>,
    _ j: Index<Int>
) where S.Element == Int {
    store.swapAt(i, j)
}

private func unshare<S: Store.`Protocol` & ~Copyable>(_ store: inout S) {
    store.unshare()
}

private final class SharedValues {
    var values: [Int]

    init(_ values: [Int]) { self.values = values }
}

private struct CopyOnWriteStore: Store.`Protocol` {
    var storage: SharedValues

    init(_ values: [Int]) { storage = SharedValues(values) }

    var capacity: Index<Int>.Count { 4 }

    subscript(slot: Index<Int>) -> Int {
        get { storage.values[Int(slot.underlying.rawValue)] }
        set {
            unshare()
            storage.values[Int(slot.underlying.rawValue)] = newValue
        }
    }

    mutating func initialize(at slot: Index<Int>, to element: consuming Int) {
        precondition(Int(slot.underlying.rawValue) == storage.values.count)
        precondition(storage.values.count < 4)
        unshare()
        storage.values.append(element)
    }

    mutating func move(at slot: Index<Int>) -> Int {
        precondition(Int(slot.underlying.rawValue) == storage.values.count - 1)
        unshare()
        return storage.values.removeLast()
    }

    mutating func swapAt(_ i: Index<Int>, _ j: Index<Int>) {
        unshare()
        storage.values.swapAt(Int(i.underlying.rawValue), Int(j.underlying.rawValue))
    }

    mutating func unshare() {
        if !isKnownUniquelyReferenced(&storage) {
            storage = SharedValues(storage.values)
        }
    }
}

@Suite
struct `Split preserves the operations of its owned planes` {
    @Test(arguments: [false, true])
    func `Swapping live elements preserves the specialized operation and lane values`(
        throughProtocol: Bool
    ) {
        var store = Store.Split(
            lanes: TailStore(values: [1, 2, 3]),
            elements: TailStore(values: [10, 20, 30])
        )

        if throughProtocol {
            swap(&store, 0, 2)
        } else {
            store.swapAt(0, 2)
        }

        let elements = store.elements.values
        let lanes = store.lanes.values
        let capacity = store.capacity
        let elementSwaps = store.elements.swapCalls
        let laneSwaps = store.lanes.swapCalls
        let moves = store.elements.moveCalls
        let initializations = store.elements.initializeCalls
        #expect(elements == [30, 20, 10])
        #expect(lanes == [1, 2, 3])
        #expect(capacity == 4)
        #expect(elementSwaps == 1)
        #expect(laneSwaps == 0)
        #expect(moves == 0)
        #expect(initializations == 0)
    }

    @Test
    func `Equal indices reach the element plane without changing either plane`() {
        var store = Store.Split(
            lanes: TailStore(values: [1, 2, 3]),
            elements: TailStore(values: [10, 20, 30])
        )
        swap(&store, 1, 1)

        let elements = store.elements.values
        let lanes = store.lanes.values
        let elementSwaps = store.elements.swapCalls
        let laneSwaps = store.lanes.swapCalls
        #expect(elements == [10, 20, 30])
        #expect(lanes == [1, 2, 3])
        #expect(elementSwaps == 1)
        #expect(laneSwaps == 0)
    }

    @Test(arguments: [false, true])
    func `Unsharing invokes both owned planes without changing their values`(
        throughProtocol: Bool
    ) {
        var store = Store.Split(
            lanes: TailStore(values: [1, 2]),
            elements: TailStore(values: [10, 20, 30])
        )
        if throughProtocol {
            unshare(&store)
        } else {
            store.unshare()
        }

        let elementCalls = store.elements.unshareCalls
        let laneCalls = store.lanes.unshareCalls
        let elements = store.elements.values
        let lanes = store.lanes.values
        let capacity = store.capacity
        #expect(elementCalls == 1)
        #expect(laneCalls == 1)
        #expect(elements == [10, 20, 30])
        #expect(lanes == [1, 2])
        #expect(capacity == 4)
    }

    @Test
    func `Unsharing a copied split detaches both backing stores and preserves its sibling`() {
        let original = Store.Split(
            lanes: CopyOnWriteStore([1, 2]),
            elements: CopyOnWriteStore([10, 20, 30])
        )
        var detached = original
        #expect(detached.lanes.storage === original.lanes.storage)
        #expect(detached.elements.storage === original.elements.storage)

        unshare(&detached)

        #expect(detached.lanes.storage !== original.lanes.storage)
        #expect(detached.elements.storage !== original.elements.storage)
        #expect(detached.lanes.storage.values == [1, 2])
        #expect(detached.elements.storage.values == [10, 20, 30])
        detached.lanes[0] = 9
        detached[0] = 90
        #expect(detached.lanes.storage.values == [9, 2])
        #expect(detached.elements.storage.values == [90, 20, 30])
        #expect(original.lanes.storage.values == [1, 2])
        #expect(original.elements.storage.values == [10, 20, 30])
    }
}
