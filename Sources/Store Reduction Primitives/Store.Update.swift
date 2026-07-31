public import Algebra_Monoid_Primitives
public import Optic_Primitives

extension Store {
    /// The transition that advances state by one action.
    ///
    /// An update is a value, not a protocol conformance: it stores the transition
    /// and is composed by combining and lifting other updates. It advances state in
    /// place — the alternative, returning a fresh state beside the effect, copies
    /// the whole state on every action — and returns a ``Store/Effect`` describing
    /// the work it wants done.
    ///
    /// ## Totality
    ///
    /// An update does not throw. A reduction that can fail is not a reduction: a
    /// failure that the domain cares about is an `Action` fed back into the store,
    /// which is also what makes it replayable in a test. The transformation
    /// combinators do carry typed throws, because a *caller's* transform may fail.
    ///
    /// ## Composition
    ///
    /// ``combined(with:)`` runs two updates over the same domain and merges their
    /// effects; it forms a monoid with ``empty``, published as ``combining``.
    /// ``lift(state:action:)`` moves an update into a wider domain, and
    /// ``optional`` moves it over state that may be absent.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let counter = Store.Update<Int, CounterAction, Job> { count, action in
    ///     switch action {
    ///     case .increment: count += 1
    ///     case .decrement: count -= 1
    ///     }
    ///     return .none
    /// }
    ///
    /// let screen = counter.lift(
    ///     state: Optic.Lens(
    ///         get: { (screen: ScreenState) in screen.count },
    ///         set: { screen, count in ScreenState(count: count, title: screen.title) }
    ///     ),
    ///     action: Optic.Prism(
    ///         embed: ScreenAction.counter,
    ///         extract: { message in
    ///             guard case .counter(let action) = message else { return nil }
    ///             return action
    ///         }
    ///     )
    /// )
    /// ```
    public struct Update<State, Action, Operation> {
        /// Advances `state` by `action` and reports the work requested.
        public let transition: @Sendable (inout State, Action) -> Store.Effect<Action, Operation>

        /// Creates an update from its transition.
        ///
        /// - Parameter transition: Advances state in place and returns the work requested.
        public init(
            _ transition: @escaping @Sendable (inout State, Action) -> Store.Effect<Action, Operation>
        ) {
            self.transition = transition
        }
    }
}

// MARK: - Conditional Conformances

extension Store.Update: Sendable {}

// MARK: - Application

extension Store.Update {
    /// Advances `state` by `action` and returns the work requested.
    ///
    /// - Parameters:
    ///   - action: The action to apply.
    ///   - state: The state to advance, in place.
    /// - Returns: The work the update asks for.
    @inlinable
    public func effect(for action: Action, in state: inout State) -> Store.Effect<Action, Operation> {
        transition(&state, action)
    }
}

// MARK: - Composition

extension Store.Update {
    /// An update that changes nothing and requests no work.
    public static var empty: Self {
        .init { _, _ in .none }
    }

    /// This update and `other`, both applied to every action.
    ///
    /// Both transitions run, in order, over the same state; their effects are
    /// merged side by side. Order matters to the state, not to the effects.
    ///
    /// - Parameter other: The update to apply after this one.
    /// - Returns: An update applying both.
    public func combined(with other: Self) -> Self {
        .init { state, action in
            let first = self.transition(&state, action)
            let second = other.transition(&state, action)
            return first.merged(with: second)
        }
    }

    /// The monoid of updates under composition.
    ///
    /// Identity is ``empty``; the operation is ``combined(with:)``.
    public static var combining: Algebra.Monoid<Self> {
        .init(identity: .empty, combining: { $0.combined(with: $1) })
    }

    /// Composes the given updates, in order.
    ///
    /// - Parameter updates: The updates to apply to every action, in order.
    public init(_ updates: [Self]) {
        self = updates.reduce(Self.empty) { $0.combined(with: $1) }
    }
}

// MARK: - Scoping

extension Store.Update {
    /// This update moved into a wider domain.
    ///
    /// A lens says where the smaller state lives inside the larger one; a prism says
    /// which of the larger domain's messages are this update's actions. A message the
    /// prism does not recognise leaves the state untouched and requests no work, which
    /// is what makes the lifted update total.
    ///
    /// Scoping is exactly a lens and a prism, so it is spelled with the ecosystem's
    /// optics rather than with the four functions they are made of.
    ///
    /// - Parameters:
    ///   - state: Focuses this update's state within the wider state.
    ///   - action: Recognises this update's actions among the wider domain's messages,
    ///     and expresses one of them back as a wider message.
    /// - Returns: An update over the wider domain.
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

    /// This update over state that may be absent.
    ///
    /// While the state is `nil` there is nothing to advance, so the action is
    /// ignored and no work is requested.
    public var optional: Store.Update<State?, Action, Operation> {
        .init { state, action in
            guard var present = state else { return .none }
            let effect = self.transition(&present, action)
            state = present
            return effect
        }
    }
}
