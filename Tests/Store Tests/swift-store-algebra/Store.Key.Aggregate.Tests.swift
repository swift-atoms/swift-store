#if Algebra
import Algebra
import Store
import Testing

@Suite
struct `Store.Key.Aggregate Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}

    enum Warnings {}

    enum Ceiling {}
}

extension `Store.Key.Aggregate Tests`.Warnings: Store::Store.Key.Aggregate {
    typealias Value = [Int]

    static var aggregation: Algebra.Monoid<[Int]> {
        .init(identity: [], combining: { $0 + $1 })
    }
}

extension `Store.Key.Aggregate Tests`.Ceiling: Store::Store.Key.Aggregate {
    typealias Value = Int

    static var aggregation: Algebra.Monoid<Int> {
        .init(identity: Int.min, combining: { Swift.max($0, $1) })
    }
}

extension `Store.Key.Aggregate Tests`.Unit {
    @Test
    func `an aggregate key defaults its initial value to the monoid identity`() {
        #expect(`Store.Key.Aggregate Tests`.Warnings.initial == [])
        #expect(`Store.Key.Aggregate Tests`.Ceiling.initial == Int.min)
    }

    @Test
    func `an aggregate key combines contributions`() {
        let monoid = `Store.Key.Aggregate Tests`.Warnings.aggregation
        let combined = monoid(monoid([1], [2]), [3])

        #expect(combined == [1, 2, 3])
    }

    @Test
    func `an aggregate key identity is two-sided`() {
        let monoid = `Store.Key.Aggregate Tests`.Ceiling.aggregation

        for contribution in [Int.min, -1, 0, 42] {
            #expect(monoid(monoid.identity, contribution) == contribution)
            #expect(monoid(contribution, monoid.identity) == contribution)
        }
    }

    @Test
    func `an aggregate key combination is associative`() {
        let monoid = `Store.Key.Aggregate Tests`.Ceiling.aggregation
        let samples = [Int.min, -3, 0, 12]

        for a in samples {
            for b in samples {
                for c in samples {
                    #expect(monoid(monoid(a, b), c) == monoid(a, monoid(b, c)))
                }
            }
        }
    }
}

extension `Store.Key.Aggregate Tests`.`Edge Case` {
    @Test
    func `aggregating no contributions yields the identity`() {
        let monoid = `Store.Key.Aggregate Tests`.Warnings.aggregation
        let contributions: [[Int]] = []
        let combined = contributions.reduce(monoid.identity) { monoid($0, $1) }

        #expect(combined == `Store.Key.Aggregate Tests`.Warnings.initial)
    }

    @Test
    func `an aggregate key keeps its monoid identity as the reported initial value`() {
        #expect(
            `Store.Key.Aggregate Tests`.Ceiling.initial
                == `Store.Key.Aggregate Tests`.Ceiling.aggregation.identity
        )
    }
}
#endif
