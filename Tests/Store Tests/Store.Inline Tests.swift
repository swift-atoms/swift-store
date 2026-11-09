import Cardinal
import Index
import Ordinal
import Store
import Tagged
import Testing

private final class Item: @unchecked Sendable {
    let id: Int
    var value: Int
    init(_ id: Int, value: Int = 0) {
        self.id = id
        self.value = value
    }
    deinit { Probe.recordDestroy(id) }
}

extension Item {
    func bump() { value += 1 }
}

private enum Probe {}

extension Probe {
    nonisolated(unsafe) static var _destroyed: [Int] = []
    static func reset() { unsafe _destroyed = [] }
    static func recordDestroy(_ id: Int) { unsafe _destroyed.append(id) }
    static var destroyed: [Int] { unsafe _destroyed }
    static var destroyedSorted: [Int] { unsafe _destroyed.sorted() }
}

enum `Store.Inline Tests` {}

extension `Store.Inline Tests` {
    @Suite(.serialized)
    struct `Inline stores preserve element mutation transfer and single destruction` {

        @Test
        func `create reports capacity empty`() {
            let s = Store::Store.Inline<Int, 4>()
            let cap = s.capacity
            let empty = s.isEmpty
            #expect(cap == Index<Int>.Count(4))
            #expect(empty)
        }

        @Test
        func `Inline storage preserves a mutated value through transfer and destroys it once`() {
            Probe.reset()
            var s = Store::Store.Inline<Item, 4>()
            s.initialize(at: 0, to: Item(7, value: 70))
            let v0 = s[0].value
            #expect(v0 == 70)
            s[0].bump()
            let v0b = s[0].value
            #expect(v0b == 71)
            let cnt = s.count
            #expect(cnt == Index<Item>.Count(1))
            let moved = s.move(at: 0)
            let mv = moved.value
            let dEmpty = Probe.destroyed.isEmpty
            #expect(mv == 71)
            #expect(dEmpty)
            _ = consume moved
            let dAfter = Probe.destroyed
            #expect(dAfter == [7])
        }

        @Test
        func `teardown destroys live prefix once`() {
            Probe.reset()
            do {
                var s = Store::Store.Inline<Item, 8>()
                s.initialize(at: 0, to: Item(1))
                s.initialize(at: 1, to: Item(2))
                s.initialize(at: 2, to: Item(3))
            }
            let ds = Probe.destroyedSorted
            #expect(ds == [1, 2, 3])
        }

        @Test
        func
            `move at every slot round trips without leaking or double freeing (F-001 pointer-escape regression)`()
        {

            Probe.reset()
            var s = Store::Store.Inline<Item, 4>()
            s.initialize(at: 0, to: Item(101))
            s.initialize(at: 1, to: Item(102))
            s.initialize(at: 2, to: Item(103))
            s.initialize(at: 3, to: Item(104))

            let m3 = s.move(at: 3)
            let m0 = s.move(at: 0)
            let m2 = s.move(at: 2)
            let m1 = s.move(at: 1)
            let ids = [m3.id, m0.id, m2.id, m1.id]
            #expect(ids == [104, 101, 103, 102])
            let emptyBeforeDrop = Probe.destroyed.isEmpty
            #expect(emptyBeforeDrop)
            _ = consume m3
            _ = consume m0
            _ = consume m2
            _ = consume m1
            let destroyedAfterConsume = Probe.destroyedSorted
            #expect(destroyedAfterConsume == [101, 102, 103, 104])
            let cnt = s.count
            #expect(cnt == .zero)
        }

        @Test
        func `non-tail initialize records the initialized slot so teardown destroys only it (#6)`() {
            Probe.reset()
            do {
                var s = Store::Store.Inline<Item, 4>()
                s.initialize(at: 2, to: Item(3))
                let ledger = s.initialization
                #expect(ledger == .one(Swift.Range<Index<Item>>(start: 2, count: .one)))
            }
            let ds = Probe.destroyedSorted
            #expect(ds == [3])
        }

        @Test
        func `non-tail move vacates exactly that slot so teardown destroys the rest once (#6)`() {
            Probe.reset()
            do {
                var s = Store::Store.Inline<Item, 4>()
                s.initialize(at: 0, to: Item(1))
                s.initialize(at: 1, to: Item(2))
                s.initialize(at: 2, to: Item(3))
                let moved = s.move(at: 0)
                let movedID = moved.id
                #expect(movedID == 1)
                _ = consume moved
                let ledger = s.initialization
                #expect(ledger == .one(Swift.Range<Index<Item>>(start: 1, count: 2)))
                s.deinitialize(at: 1)
            }
            let ds = Probe.destroyedSorted
            #expect(ds == [1, 2, 3])
        }

        @Test
        func `wrapped initialization keeps two ranges and teardown destroys both once (#6)`() {
            Probe.reset()
            do {
                var s = Store::Store.Inline<Item, 4>()
                s.initialize(at: 0, to: Item(1))
                s.initialize(at: 3, to: Item(4))
                let ledger = s.initialization
                #expect(
                    ledger
                        == .two(
                            first: Swift.Range<Index<Item>>(start: 3, count: .one),
                            second: Swift.Range<Index<Item>>(start: 0, count: .one)
                        )
                )
            }
            let ds = Probe.destroyedSorted
            #expect(ds == [1, 4])
        }

        @Test
        func `swapAt exchanges elements in place without changing the ledger (#6)`() {
            Probe.reset()
            do {
                var s = Store::Store.Inline<Item, 8>()
                s.initialize(at: 0, to: Item(0))
                s.initialize(at: 1, to: Item(1))
                s.initialize(at: 2, to: Item(2))
                s.initialize(at: 3, to: Item(3))
                s.initialize(at: 4, to: Item(4))
                s.initialize(at: 5, to: Item(5))
                s.swapAt(1, 4)
                let ids = [s[1].id, s[4].id]
                #expect(ids == [4, 1])
                let count = s.count
                #expect(count == Index<Item>.Count(6))
            }
            let ds = Probe.destroyedSorted
            #expect(ds == [0, 1, 2, 3, 4, 5])
        }

        @Test
        func `whole-store defaults visit and clear only the ledger's slots (#6)`() {
            Probe.reset()
            var s = Store::Store.Inline<Item, 4>()
            s.initialize(at: 1, to: Item(2))
            s.initialize(at: 2, to: Item(3))
            var visited: [Int] = []
            s.forEach { visited.append($0.id) }
            let sum = s.reduce(into: 0) { $0 += $1.id }
            let found = s.contains { $0.id == 3 }
            #expect(visited == [2, 3])
            #expect(sum == 5)
            #expect(found)
            s.clear()
            let empty = s.isEmpty
            let ds = Probe.destroyedSorted
            #expect(empty)
            #expect(ds == [2, 3])

            var ints = Store::Store.Inline<Int, 3>()
            ints.fill(with: 7)
            var copied = Store::Store.Inline<Int, 3>()
            ints.copy(to: &copied)
            let total = copied.reduce(into: 0) { $0 += $1 }
            #expect(total == 21)
        }

        @Test
        func `move only elements ride the seam`() {

            Probe2.reset()
            do {
                var s = Store::Store.Inline<MoveOnly, 4>()
                s.initialize(at: 0, to: MoveOnly(id: 1))
                s.initialize(at: 1, to: MoveOnly(id: 2))
                let borrowedID = s[0].id
                #expect(borrowedID == 1)
                let cnt = s.count
                #expect(cnt == Index<MoveOnly>.Count(2))
                let moved = s.move(at: 1)
                let movedID = moved.id
                #expect(movedID == 2)
                _ = consume moved
                let mid = Probe2.destroyedSorted
                #expect(mid == [2])
            }
            let ds = Probe2.destroyedSorted
            #expect(ds == [1, 2])
        }
    }
}

private struct MoveOnly: ~Copyable {
    let id: Int
    deinit { Probe2.recordDestroy(id) }
}

private enum Probe2 {}

extension Probe2 {
    nonisolated(unsafe) static var _destroyed: [Int] = []
    static func reset() { unsafe _destroyed = [] }
    static func recordDestroy(_ id: Int) { unsafe _destroyed.append(id) }
    static var destroyedSorted: [Int] { unsafe _destroyed.sorted() }
}
