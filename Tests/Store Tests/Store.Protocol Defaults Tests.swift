import Store
import Testing

private struct CheckedSlots<Element>: Store.`Protocol`, ~Copyable {
    var slots: [Element?]
    var movedSlots: [Int] = []
    var initializedSlots: [Int] = []

    init(_ slots: [Element?]) { self.slots = slots }

    var capacity: Index<Element>.Count { .init(UInt(slots.count)) }

    subscript(slot: Index<Element>) -> Element {
        get { slots[Int(slot.underlying.rawValue)]! }
        set {
            let position = Int(slot.underlying.rawValue)
            precondition(slots[position] != nil)
            slots[position] = newValue
        }
    }

    mutating func initialize(at slot: Index<Element>, to element: consuming Element) {
        let position = Int(slot.underlying.rawValue)
        precondition(slots[position] == nil)
        initializedSlots.append(position)
        slots[position] = element
    }

    mutating func move(at slot: Index<Element>) -> Element {
        let position = Int(slot.underlying.rawValue)
        let value = slots[position]!
        movedSlots.append(position)
        slots[position] = nil
        return value
    }
}

private final class DestructionLog {
    var ids: [Int] = []
}

private final class TrackedItem {
    let id: Int
    let log: DestructionLog

    init(_ id: Int, log: DestructionLog) {
        self.id = id
        self.log = log
    }

    deinit { log.ids.append(id) }
}

private enum VisitFailure: Error {
    case stopped
}

@Suite
struct `Store defaults preserve valid slot states and callback failures` {
    @Test(arguments: [false, true])
    func `Overlapping moves preserve element order and leave the vacated slot empty`(
        towardHigherSlots: Bool
    ) {
        var store = CheckedSlots<Int>(
            towardHigherSlots ? [10, 20, 30, nil] : [nil, 10, 20, 30]
        )
        store.moveInitialize(
            from: towardHigherSlots ? 0 : 1,
            to: towardHigherSlots ? 1 : 0,
            count: 3
        )

        let slots = store.slots
        let moves = store.movedSlots
        let initializations = store.initializedSlots
        #expect(slots == (towardHigherSlots ? [nil, 10, 20, 30] : [10, 20, 30, nil]))
        #expect(moves == (towardHigherSlots ? [2, 1, 0] : [1, 2, 3]))
        #expect(initializations == (towardHigherSlots ? [3, 2, 1] : [0, 1, 2]))
    }

    @Test
    func `Moving zero elements or using equal positions leaves every slot untouched`() {
        var store = CheckedSlots<Int>([10, 20, nil])
        store.moveInitialize(from: 0, to: 2, count: 0)
        store.moveInitialize(from: 0, to: 0, count: 2)
        store.move(from: 1, to: 1)

        let slots = store.slots
        let moves = store.movedSlots
        let initializations = store.initializedSlots
        #expect(slots == [10, 20, nil])
        #expect(moves.isEmpty)
        #expect(initializations.isEmpty)
    }

    @Test
    func `Moving one element transfers it to a vacant slot that can be reused`() {
        var store = CheckedSlots<Int>([10, nil, nil])
        store.move(from: 0, to: 2)
        let afterMove = store.slots
        #expect(afterMove == [nil, nil, 10])
        store.initialize(at: 0, to: 20)
        let afterReuse = store.slots
        #expect(afterReuse == [20, nil, 10])
    }

    @Test
    func `Copying an explicit live prefix preserves its source and unused destination slots`() {
        let source = CheckedSlots<Int>([10, 20, nil, nil])
        var destination = CheckedSlots<Int>([nil, nil, 99])
        source.copy(to: &destination, count: 2)
        source.copy(to: &destination, count: 0)

        let original = source.slots
        let copied = destination.slots
        let initializations = destination.initializedSlots
        #expect(original == [10, 20, nil, nil])
        #expect(copied == [10, 20, 99])
        #expect(initializations == [0, 1])
    }

    @Test
    func `Filling an explicit vacant range preserves neighboring live slots`() {
        var store = CheckedSlots<Int>([1, nil, nil, 4])
        store.fill(range: 1..<3, with: 7)
        store.fill(range: 2..<2, with: 99)

        let slots = store.slots
        let initializations = store.initializedSlots
        #expect(slots == [1, 7, 7, 4])
        #expect(initializations == [1, 2])
    }

    @Test
    func `Explicit deinitialization destroys only the requested live slots once`() {
        let log = DestructionLog()
        do {
            var store = CheckedSlots<TrackedItem>([
                TrackedItem(0, log: log), TrackedItem(1, log: log),
                TrackedItem(2, log: log), TrackedItem(3, log: log), nil,
            ])
            store.deinitialize(range: 1..<3)
            #expect(log.ids.sorted() == [1, 2])
            store.deinitialize(at: 3)
            store.deinitialize(range: 0..<0)
            #expect(log.ids.sorted() == [1, 2, 3])

            let liveIDs = store.slots.map { $0?.id }
            #expect(liveIDs == [0, nil, nil, nil, nil])
        }
        #expect(log.ids.sorted() == [0, 1, 2, 3])
    }

    @Test(arguments: [false, true])
    func `Clearing a fully initialized store destroys every value exactly once`(
        throughRemoveAll: Bool
    ) {
        let log = DestructionLog()
        do {
            var store = CheckedSlots<TrackedItem>([
                TrackedItem(0, log: log), TrackedItem(1, log: log),
            ])
            if throughRemoveAll { store.removeAll() } else { store.clear() }
            let vacant = store.slots.allSatisfy { $0 == nil }
            #expect(vacant)
            #expect(log.ids.sorted() == [0, 1])
        }
        #expect(log.ids.sorted() == [0, 1])
    }

    @Test
    func `Whole store defaults operate on fully initialized or fully vacant capacity`() {
        var source = CheckedSlots<Int>([nil, nil, nil])
        source.fill(with: 7)
        var destination = CheckedSlots<Int>([nil, nil, nil])
        source.copy(to: &destination)
        let copied = destination.slots
        #expect(copied == [7, 7, 7])

        var visited: [Int] = []
        destination.forEach { visited.append($0) }
        let sum = destination.reduce(into: 0) { $0 += $1 }
        let found = destination.contains(7)
        let missing = destination.contains(8)
        #expect(visited == [7, 7, 7])
        #expect(sum == 21)
        #expect(found)
        #expect(!missing)
    }

    @Test(arguments: ["forEach", "reduce", "contains"])
    func `Throwing callbacks stop before visiting later slots and preserve the source`(
        operation: String
    ) {
        let store = CheckedSlots<Int>([10, 20, 30])
        var visited: [Int] = []
        var partial = 0
        var failure: VisitFailure?
        do throws(VisitFailure) {
            switch operation {
            case "forEach":
                try store.forEach { (value: borrowing Int) throws(VisitFailure) in
                    visited.append(copy value)
                    if value == 20 { throw .stopped }
                }
            case "reduce":
                _ = try store.reduce(into: 0) {
                    (sum: inout Int, value: borrowing Int) throws(VisitFailure) in
                    visited.append(copy value)
                    if value == 20 { throw .stopped }
                    sum += value
                    partial = sum
                }
            default:
                _ = try store.contains { (value: borrowing Int) throws(VisitFailure) -> Bool in
                    visited.append(copy value)
                    if value == 20 { throw .stopped }
                    return false
                }
            }
        } catch {
            failure = error
        }

        let slots = store.slots
        #expect(failure == .stopped)
        #expect(visited == [10, 20])
        #expect(slots == [10, 20, 30])
        if operation == "reduce" { #expect(partial == 10) }
    }

    @Test
    func `A matching predicate stops visiting the remaining initialized slots`() {
        let store = CheckedSlots<Int>([10, 20, 30])
        var visited: [Int] = []
        let found = store.contains {
            visited.append($0)
            return $0 == 20
        }
        #expect(found)
        #expect(visited == [10, 20])
    }
}
