public import Algebra_Monoid_Primitives
public import Optic_Primitives

extension Store {

    @frozen
    public struct Update<State, Action, Operation> {

        public let transition: @Sendable (inout State, Action) -> Store.Effect<Action, Operation>

        public init(
            _ transition:
                @escaping @Sendable (inout State, Action) -> Store.Effect<Action, Operation>
        ) {
            self.transition = transition
        }
    }
}

extension Store.Update: Sendable {}

extension Store.Update {

    @inlinable
    public func effect(
        for action: Action,
        in state: inout State
    ) -> Store.Effect<Action, Operation> {
        transition(&state, action)
    }
}

extension Store.Update {

    public static var empty: Self {
        .init { _, _ in .none }
    }

    public func combined(with other: Self) -> Self {
        .init { state, action in
            let first = self.transition(&state, action)
            let second = other.transition(&state, action)
            return first.merged(with: second)
        }
    }

    public static var combining: Algebra.Monoid<Self> {
        .init(identity: .empty, combining: { $0.combined(with: $1) })
    }

    public init(_ updates: [Self]) {
        self = updates.reduce(Self.empty) { $0.combined(with: $1) }
    }
}

extension Store.Update {

    public func lift<Whole, Message>(
        state: Optic.Lens<Whole, State>,
        action: Optic.Prism<Message, Action>
    ) -> Store.Update<Whole, Message, Operation> {
        .init { whole, message in
            guard let inner = action.extract(message) else { return .none }
            var part = state.get(whole)
            let effect = self.transition(&part, inner)
            whole = state.set(whole, part)
            return effect.map(action: action.embed)
        }
    }

    public var optional: Store.Update<State?, Action, Operation> {
        .init { state, action in
            guard var present = state else { return .none }
            let effect = self.transition(&present, action)
            state = present
            return effect
        }
    }
}
