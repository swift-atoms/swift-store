import Store_Reduction_Primitives_Test_Support
import Testing

@Suite
struct `Store.Key Tests` {

    /// A downward value: the palette a subtree renders with.
    enum Palette: Store.Key.`Protocol` {
        static var initial: Int { 7 }
    }

    /// A downward command: a value whose type is a function.
    enum Dismiss: Store.Key.`Protocol` {
        static var initial: @Sendable () -> Int { { 0 } }
    }

    /// An upward aggregation over a free monoid.
    enum Warnings: Store.Key.Aggregate {
        static var aggregation: Algebra.Monoid<[Int]> {
            .init(identity: [], combining: { $0 + $1 })
        }
    }

    /// An upward aggregation whose identity is not empty.
    enum Ceiling: Store.Key.Aggregate {
        static var aggregation: Algebra.Monoid<Int> {
            .init(identity: Int.min, combining: { Swift.max($0, $1) })
        }
    }

    @Suite
    struct Unit {

        @Test
        func `a plain key reports its initial value`() {
            #expect(`Store.Key Tests`.Palette.initial == 7)
        }

        @Test
        func `a command key initial value is callable`() {
            #expect(`Store.Key Tests`.Dismiss.initial() == 0)
        }

        @Test
        func `an aggregate key defaults its initial value to the monoid identity`() {
            #expect(`Store.Key Tests`.Warnings.initial == [])
            #expect(`Store.Key Tests`.Ceiling.initial == Int.min)
        }

        @Test
        func `an aggregate key combines contributions`() {
            let monoid = `Store.Key Tests`.Warnings.aggregation
            let combined = monoid(monoid([1], [2]), [3])

            #expect(combined == [1, 2, 3])
        }

        @Test
        func `an aggregate key identity is two-sided`() {
            let monoid = `Store.Key Tests`.Ceiling.aggregation

            for contribution in [Int.min, -1, 0, 42] {
                #expect(monoid(monoid.identity, contribution) == contribution)
                #expect(monoid(contribution, monoid.identity) == contribution)
            }
        }

        @Test
        func `an aggregate key combination is associative`() {
            let monoid = `Store.Key Tests`.Ceiling.aggregation
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

    @Suite
    struct `Edge Case` {

        @Test
        func `aggregating no contributions yields the identity`() {
            let monoid = `Store.Key Tests`.Warnings.aggregation
            let contributions: [[Int]] = []
            let combined = contributions.reduce(monoid.identity) { monoid($0, $1) }

            #expect(combined == `Store.Key Tests`.Warnings.initial)
        }

        @Test
        func `an aggregate key keeps its monoid identity as the reported initial value`() {
            #expect(`Store.Key Tests`.Ceiling.initial == `Store.Key Tests`.Ceiling.aggregation.identity)
        }
    }
}
