import Store_Reduction_Primitives_Test_Support
import Testing

@Suite
struct `Store.Update Tests` {

    enum Counter: Equatable, Sendable {
        case increment
        case decrement
    }

    enum Message: Equatable, Sendable {
        case counter(Counter)
        case reset
    }

    enum Job: Equatable, Sendable {
        case beacon
        case audit
    }

    struct Screen: Equatable, Sendable {
        var count: Int
        var resets: Int
    }

    /// Advances a bare count and asks for a beacon on every increment.
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

    /// Lifts a counter update into the screen domain.
    static func lifted(
        _ update: Store.Update<Int, Counter, Job>
    ) -> Store.Update<Screen, Message, Job> {
        update.lift(
            get: { screen in screen.count },
            set: { screen, count in Screen(count: count, resets: screen.resets) },
            extract: { message in
                guard case .counter(let action) = message else { return nil }
                return action
            },
            embed: Message.counter
        )
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
                let trailingEffect = counter.combined(with: empty).effect(for: action, in: &trailing)

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
            _ = Store.Update([`Store.Update Tests`.counter, step]).effect(for: .increment, in: &count)

            #expect(count == 10)
        }

        @Test
        func `lifting advances the nested state`() {
            let screen = `Store.Update Tests`.lifted(`Store.Update Tests`.counter)

            var state = Screen(count: 4, resets: 1)
            _ = screen.effect(for: .counter(.increment), in: &state)

            #expect(state == Screen(count: 5, resets: 1))
        }

        @Test
        func `lifting embeds the child actions of the effect`() {
            let sending = Store.Update<Int, Counter, Job> { _, _ in .send(.decrement) }
            let screen = `Store.Update Tests`.lifted(sending)

            var state = Screen(count: 0, resets: 0)
            let effect = screen.effect(for: .counter(.increment), in: &state)

            #expect(effect == .send(.counter(.decrement)))
        }

        @Test
        func `lifting ignores an unrecognised message`() {
            let screen = `Store.Update Tests`.lifted(`Store.Update Tests`.counter)

            var state = Screen(count: 4, resets: 1)
            let effect = screen.effect(for: .reset, in: &state)

            #expect(state == Screen(count: 4, resets: 1))
            #expect(effect == .none)
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

        @Test
        func `lifting an update that asks for nothing asks for nothing`() {
            let quiet = Store.Update<Int, Counter, Job> { count, _ in
                count += 1
                return .none
            }
            let screen = `Store.Update Tests`.lifted(quiet)

            var state = Screen(count: 0, resets: 0)
            let effect = screen.effect(for: .counter(.increment), in: &state)

            #expect(state.count == 1)
            #expect(effect == .none)
        }

        @Test
        func `lifting writes the nested state back and leaves the rest alone`() {
            let screen = `Store.Update Tests`.lifted(`Store.Update Tests`.counter)

            var state = Screen(count: 0, resets: 3)
            _ = screen.effect(for: .counter(.decrement), in: &state)

            #expect(state.count == -1)
            #expect(state.resets == 3)
        }
    }
}
