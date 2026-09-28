#if Optic
import Optic
import Store
import Testing

@Suite
struct `Store.Update.Lift Tests` {
    @Suite struct Integration {}

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

    static let counter = Store::Store.Update<Int, Counter, Job> { count, action in
        switch action {
        case .increment:
            count += 1
            return .run(.beacon)

        case .decrement:
            count -= 1
            return .none
        }
    }

    static func lifted(
        _ update: Store::Store.Update<Int, Counter, Job>
    ) -> Store::Store.Update<Screen, Message, Job> {
        update.lift(
            state: Optic<Screen, Screen, Int, Int>.SendableLens(
                get: { screen in screen.count },
                set: { screen, count in Screen(count: count, resets: screen.resets) }
            ),
            action: Optic<Message, Message, Counter, Counter>.SendablePrism(
                embed: { Message.counter($0) },
                extract: { message in
                    guard case .counter(let action) = message else { return nil }
                    return action
                }
            )
        )
    }

    @Suite
    struct Unit {

        @Test
        func `lifting advances the nested state`() {
            let screen = `Store.Update.Lift Tests`.lifted(`Store.Update.Lift Tests`.counter)

            var state = Screen(count: 4, resets: 1)
            let effect = screen.effect(for: .counter(.increment), in: &state)

            #expect(state == Screen(count: 5, resets: 1))
            #expect(effect == .run(.beacon))
        }

        @Test
        func `lifting embeds the child actions of the effect`() {
            let sending = Store::Store.Update<Int, Counter, Job> { _, _ in .send(.decrement) }
            let screen = `Store.Update.Lift Tests`.lifted(sending)

            var state = Screen(count: 0, resets: 0)
            let effect = screen.effect(for: .counter(.increment), in: &state)

            #expect(effect == .send(.counter(.decrement)))
        }

        @Test
        func `lifting ignores an unrecognised message`() {
            let screen = `Store.Update.Lift Tests`.lifted(`Store.Update.Lift Tests`.counter)

            var state = Screen(count: 4, resets: 1)
            let effect = screen.effect(for: .reset, in: &state)

            #expect(state == Screen(count: 4, resets: 1))
            #expect(effect == .none)
        }
    }

    @Suite
    struct `Edge Case` {

        @Test
        func `lifting an update that asks for nothing asks for nothing`() {
            let quiet = Store::Store.Update<Int, Counter, Job> { count, _ in
                count += 1
                return .none
            }
            let screen = `Store.Update.Lift Tests`.lifted(quiet)

            var state = Screen(count: 0, resets: 0)
            let effect = screen.effect(for: .counter(.increment), in: &state)

            #expect(state.count == 1)
            #expect(effect == .none)
        }

        @Test
        func `lifting writes the nested state back and leaves the rest alone`() {
            let screen = `Store.Update.Lift Tests`.lifted(`Store.Update.Lift Tests`.counter)

            var state = Screen(count: 0, resets: 3)
            _ = screen.effect(for: .counter(.decrement), in: &state)

            #expect(state.count == -1)
            #expect(state.resets == 3)
        }
    }
}
#endif
