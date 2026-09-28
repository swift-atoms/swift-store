#if Algebra
import Algebra
import Store
import Testing

@Suite
struct `Store.Effect.Monoid Tests` {
    @Suite struct Unit {}

    enum Action: Equatable, Sendable {
        case first
        case second
        case third
    }

    enum Job: Equatable, Sendable {
        case load
        case save
    }

    typealias Effect = Store::Store.Effect<Action, Job>

    static let samples: [Effect] = [
        .none,
        .send(.first),
        .run(.load),
        .merge([.send(.first), .run(.save)]),
        .sequence([.send(.second), .run(.load)]),
        .merge([]),
        .sequence([]),
    ]
}

extension `Store.Effect.Monoid Tests`.Unit {

    @Test
    func `the merging monoid agrees with the combinator`() {
        let monoid = `Store.Effect.Monoid Tests`.Effect.merging
        #expect(monoid.identity == .none)

        for a in `Store.Effect.Monoid Tests`.samples {
            for b in `Store.Effect.Monoid Tests`.samples {
                #expect(monoid(a, b) == a.merged(with: b))
            }
        }
    }

    @Test
    func `the sequencing monoid agrees with the combinator`() {
        let monoid = `Store.Effect.Monoid Tests`.Effect.sequencing
        #expect(monoid.identity == .none)

        for a in `Store.Effect.Monoid Tests`.samples {
            for b in `Store.Effect.Monoid Tests`.samples {
                #expect(monoid(a, b) == a.followed(by: b))
            }
        }
    }
}

extension `Store.Effect.Monoid Tests`.Unit {

    @Test
    func `the combining monoid agrees with the combinator`() {
        typealias Update = Store::Store.Update<Int, `Store.Effect.Monoid Tests`.Action, `Store.Effect.Monoid Tests`.Job>

        let increment = Update { count, _ in
            count += 1
            return .none
        }

        let monoid = Update.combining

        var viaMonoid = 0
        _ = monoid(increment, increment).effect(for: .first, in: &viaMonoid)

        var viaCombinator = 0
        _ = increment.combined(with: increment).effect(for: .first, in: &viaCombinator)

        #expect(viaMonoid == viaCombinator)

        var identity = 5
        let effect = monoid.identity.effect(for: .first, in: &identity)
        #expect(identity == 5)
        #expect(effect == .none)
    }
}
#endif
