import Store_Reduction_Primitives_Test_Support
import Testing

@Suite
struct `Store.Effect Tests` {

    enum Action: Equatable, Sendable {
        case first
        case second
        case third
    }

    enum Job: Equatable, Sendable {
        case load
        case save
    }

    typealias Effect = Store.Effect<Action, Job>

    /// Representative values covering every case, including nested groups.
    static let samples: [Effect] = [
        .none,
        .send(.first),
        .run(.load),
        .merge([.send(.first), .run(.save)]),
        .sequence([.send(.second), .run(.load)]),
        .merge([]),
        .sequence([]),
    ]

    @Suite
    struct Unit {

        @Test
        func `none is a two-sided identity for merging`() {
            for effect in `Store.Effect Tests`.samples {
                #expect(effect.merged(with: .none) == effect)
                #expect(Effect.none.merged(with: effect) == effect)
            }
        }

        @Test
        func `none is a two-sided identity for sequencing`() {
            for effect in `Store.Effect Tests`.samples {
                #expect(effect.followed(by: .none) == effect)
                #expect(Effect.none.followed(by: effect) == effect)
            }
        }

        @Test
        func `merging is associative`() {
            let samples = `Store.Effect Tests`.samples
            for a in samples {
                for b in samples {
                    for c in samples {
                        let left = a.merged(with: b).merged(with: c)
                        let right = a.merged(with: b.merged(with: c))
                        #expect(left == right)
                    }
                }
            }
        }

        @Test
        func `sequencing is associative`() {
            let samples = `Store.Effect Tests`.samples
            for a in samples {
                for b in samples {
                    for c in samples {
                        let left = a.followed(by: b).followed(by: c)
                        let right = a.followed(by: b.followed(by: c))
                        #expect(left == right)
                    }
                }
            }
        }

        @Test
        func `merging flattens a nested merge`() {
            let merged = Effect.merge([.send(.first), .send(.second)])
                .merged(with: .merge([.run(.load)]))

            #expect(merged == .merge([.send(.first), .send(.second), .run(.load)]))
        }

        @Test
        func `sequencing flattens a nested sequence`() {
            let sequenced = Effect.sequence([.send(.first)])
                .followed(by: .sequence([.send(.second), .run(.save)]))

            #expect(sequenced == .sequence([.send(.first), .send(.second), .run(.save)]))
        }

        @Test
        func `merging keeps a sequence whole`() {
            let inner = Effect.sequence([.send(.first), .send(.second)])
            let merged = inner.merged(with: .run(.load))

            #expect(merged == .merge([inner, .run(.load)]))
        }

        @Test
        func `sequencing keeps a merge whole`() {
            let inner = Effect.merge([.send(.first), .send(.second)])
            let sequenced = inner.followed(by: .run(.load))

            #expect(sequenced == .sequence([inner, .run(.load)]))
        }

        @Test
        func `the merging monoid agrees with the combinator`() {
            let monoid = Effect.merging
            #expect(monoid.identity == .none)

            for a in `Store.Effect Tests`.samples {
                for b in `Store.Effect Tests`.samples {
                    #expect(monoid(a, b) == a.merged(with: b))
                }
            }
        }

        @Test
        func `the sequencing monoid agrees with the combinator`() {
            let monoid = Effect.sequencing
            #expect(monoid.identity == .none)

            for a in `Store.Effect Tests`.samples {
                for b in `Store.Effect Tests`.samples {
                    #expect(monoid(a, b) == a.followed(by: b))
                }
            }
        }

        @Test
        func `mapping actions with identity leaves the effect unchanged`() {
            for effect in `Store.Effect Tests`.samples {
                let mapped = effect.map(action: { $0 })
                #expect(mapped == effect)
            }
        }

        @Test
        func `mapping actions rewrites every send and preserves structure`() {
            let effect = Effect.merge([
                .send(.first),
                .sequence([.send(.second), .run(.load)]),
            ])

            let mapped: Store.Effect<Int, Job> = effect.map { action in
                switch action {
                case .first: return 1
                case .second: return 2
                case .third: return 3
                }
            }

            #expect(
                mapped == .merge([
                    .send(1),
                    .sequence([.send(2), .run(.load)]),
                ])
            )
        }

        @Test
        func `mapping actions composes`() {
            let effect = Effect.merge([.send(.first), .sequence([.send(.second)])])

            let once: Store.Effect<Int, Job> = effect.map { $0 == .first ? 1 : 2 }
            let twice: Store.Effect<String, Job> = once.map { "\($0)" }
            let fused: Store.Effect<String, Job> = effect.map { $0 == .first ? "1" : "2" }

            #expect(twice == fused)
        }

        @Test
        func `mapping operations leaves actions untouched`() {
            let effect = Effect.sequence([.send(.first), .run(.load), .merge([.run(.save)])])

            let mapped: Store.Effect<Action, Int> = effect.map { operation in
                operation == .load ? 0 : 1
            }

            #expect(
                mapped == .sequence([
                    .send(.first),
                    .run(0),
                    .merge([.run(1)]),
                ])
            )
        }
    }

    @Suite
    struct `Edge Case` {

        @Test
        func `merging two nones is none`() {
            #expect(Effect.none.merged(with: .none) == .none)
        }

        @Test
        func `an empty merge is absorbed rather than nested`() {
            let merged = Effect.send(.first).merged(with: .merge([]))
            #expect(merged == .merge([.send(.first)]))
        }

        @Test
        func `merging does not flatten into a sequence`() {
            let merged = Effect.sequence([.send(.first)]).merged(with: .sequence([.send(.second)]))

            #expect(
                merged == .merge([
                    .sequence([.send(.first)]),
                    .sequence([.send(.second)]),
                ])
            )
        }

        @Test
        func `mapping actions propagates a typed failure`() {
            struct Refusal: Swift.Error, Equatable {}

            let effect = Effect.merge([.send(.first), .run(.load)])

            var thrown: Refusal?
            do throws(Refusal) {
                _ = try effect.map { (_: Action) throws(Refusal) -> Int in throw Refusal() }
            } catch {
                thrown = error
            }

            #expect(thrown == Refusal())
        }

        @Test
        func `mapping a run-only effect never calls the action transform`() {
            let effect = Effect.merge([.run(.load), .sequence([.run(.save)])])

            let mapped: Store.Effect<Int, Job> = effect.map { _ in
                Issue.record("the action transform must not run for an effect with no sends")
                return 0
            }

            #expect(mapped == .merge([.run(.load), .sequence([.run(.save)])]))
        }
    }
}
