import Index
import Store
import Testing

private typealias Plane<Element: ~Copyable> = Store.Inline<Element, 4>

@Suite
struct `Store Split Tests` {

    @Test
    func `payload seam forwards to element plane`() {
        var split = Store.Split(
            lanes: Plane<UInt8>(),
            elements: Plane<Int>()
        )
        let cap = split.capacity
        #expect(cap == Index<Int>.Count(4))

        let first = Index<Int>(0)
        let second = Index<Int>(1)
        split.initialize(at: first, to: 42)
        split.initialize(at: second, to: 43)
        let v0 = split[first]
        let v1 = split[second]
        #expect(v0 == 42)
        #expect(v1 == 43)

        split[first] = 99
        let v0b = split[first]
        #expect(v0b == 99)

        let moved = split.move(at: second)
        #expect(moved == 43)
    }

    @Test
    func `lane plane is independently accessible`() {
        var split = Store.Split(
            lanes: Plane<UInt8>(),
            elements: Plane<Int>()
        )

        let firstLane = Index<UInt8>(0)
        let secondLane = Index<UInt8>(1)
        let firstElement = Index<Int>(0)
        split.lanes.initialize(at: firstLane, to: 0x80)
        split.lanes.initialize(at: secondLane, to: 0x01)
        split.initialize(at: firstElement, to: 1000)

        let lane0 = split.lanes[firstLane]
        let lane1 = split.lanes[secondLane]
        let laneCap = split.lanes.capacity
        let payload0 = split[firstElement]
        #expect(lane0 == 0x80)
        #expect(lane1 == 0x01)
        #expect(laneCap == Index<UInt8>.Count(4))
        #expect(payload0 == 1000)
    }
}
