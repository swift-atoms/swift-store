import Store
import Testing

@Suite
struct `Store.Update Tests` {
    @Suite struct Integration {}

    enum Counter: Equatable, Sendable {
        case increment
        case decrement
    }

    enum Job: Equatable, Sendable {
        case beacon
        case audit
    }

    static let counter = Store.Update<Int, Counter, Job> { count, action in
        switch action {
        case .increment:
            count += 1
            return .run(.beacon)

        case .decrement:
            count -= 1
            return .none
        }
    }

    @Suite
    struct Unit {

        @Test
        func `empty changes nothing and asks for nothing`() {
            var count = 7
            let effect = Store.Update<Int, Counter, Job>.empty.effect(for: .increment, in: &count)

            #expect(count == 7)
            #expect(effect == .none)
        }

        @Test
        func `applying an update advances the state`() {
            var count = 0
            let effect = `Store.Update Tests`.counter.effect(for: .increment, in: &count)

            #expect(count == 1)
            #expect(effect == .run(.beacon))
        }

        @Test
        func `combining runs both updates over the same state`() {
            let twice = `Store.Update Tests`.counter.combined(with: `Store.Update Tests`.counter)

            var count = 0
            _ = twice.effect(for: .increment, in: &count)

            #expect(count == 2)
        }

        @Test
        func `combining merges the effects of both updates`() {
            let twice = `Store.Update Tests`.counter.combined(with: `Store.Update Tests`.counter)

            var count = 0
            let effect = twice.effect(for: .increment, in: &count)

            #expect(effect == .merge([.run(.beacon), .run(.beacon)]))
        }

        @Test
        func `empty is a two-sided identity for combining`() {
            let counter = `Store.Update Tests`.counter
            let empty = Store.Update<Int, Counter, Job>.empty

            for action in [Counter.increment, .decrement] {
                var direct = 3
                var leading = 3
                var trailing = 3

                let directEffect = counter.effect(for: action, in: &direct)
                let leadingEffect = empty.combined(with: counter).effect(for: action, in: &leading)
                let trailingEffect = counter.combined(with: empty).effect(
                    for: action,
                    in: &trailing
                )

                #expect(leading == direct)
                #expect(trailing == direct)
                #expect(leadingEffect == directEffect)
                #expect(trailingEffect == directEffect)
            }
        }

        @Test
        func `combining is associative`() {
            let step = Store.Update<Int, Counter, Job> { count, _ in
                count *= 2
                return .run(.audit)
            }
            let counter = `Store.Update Tests`.counter

            var left = 5
            var right = 5

            let leftEffect = counter.combined(with: step).combined(with: counter)
                .effect(for: .increment, in: &left)
            let rightEffect = counter.combined(with: step.combined(with: counter))
                .effect(for: .increment, in: &right)

            #expect(left == right)
            #expect(leftEffect == rightEffect)
        }

        @Test
        func `an array of updates applies every element in order`() {
            let step = Store.Update<Int, Counter, Job> { count, _ in
                count *= 10
                return .none
            }

            var count = 0
            _ = Store.Update([`Store.Update Tests`.counter, step]).effect(
                for: .increment,
                in: &count
            )

            #expect(count == 10)
        }

        @Test
        func `optional advances present state`() {
            var state: Int? = 2
            let effect = `Store.Update Tests`.counter.optional.effect(for: .increment, in: &state)

            #expect(state == 3)
            #expect(effect == .run(.beacon))
        }
    }

    @Suite
    struct `Edge Case` {

        @Test
        func `optional ignores absent state`() {
            var state: Int?
            let effect = `Store.Update Tests`.counter.optional.effect(for: .increment, in: &state)

            #expect(state == nil)
            #expect(effect == .none)
        }

        @Test
        func `an empty array of updates is the empty update`() {
            var count = 9
            let effect = Store.Update<Int, Counter, Job>([]).effect(for: .increment, in: &count)

            #expect(count == 9)
            #expect(effect == .none)
        }
    }
}
