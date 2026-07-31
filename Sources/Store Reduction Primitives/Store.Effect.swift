public import Algebra_Monoid_Primitives

extension Store {
    /// A description of the work an update asks for.
    ///
    /// An effect is data. Producing one performs nothing: an update returns an
    /// effect, and whoever interprets the update decides what running it means.
    /// That separation is what makes an update a total function of its inputs, and
    /// what makes a reduction reproducible in a test.
    ///
    /// ## The Leaf Is Yours
    ///
    /// `Operation` is the type of a unit of work, and this package never inspects
    /// it. A runtime that performs asynchronous work instantiates `Operation` with
    /// its own job type; a runtime with no side effects at all instantiates it with
    /// `Never`. Cancellation needs no case of its own for the same reason — a
    /// request to cancel is an operation like any other.
    ///
    /// Keeping the leaf abstract is what lets this type hold no concurrency, no
    /// scheduler, and no clock, and so remain deployable where those do not exist.
    ///
    /// ## Composition
    ///
    /// Effects compose two ways, and the two do not mix: ``merged(with:)`` places
    /// effects side by side, ``followed(by:)`` places them in order. Each forms a
    /// monoid with ``none`` as its identity — published as ``merging`` and
    /// ``sequencing`` — and each flattens only into its own case, so a concurrent
    /// group nested inside a serial group keeps its meaning.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let effect = Store.Effect<Action, Job>.send(.started)
    ///     .followed(by: .run(Job.load))
    ///     .merged(with: .run(Job.beacon))
    /// ```
    public enum Effect<Action, Operation> {
        /// No work is requested.
        case none

        /// Feed an action back into the store.
        case send(Action)

        /// Perform one unit of work, as the interpreter understands it.
        case run(Operation)

        /// Perform the given effects side by side, in no guaranteed order.
        case merge([Self])

        /// Perform the given effects one after another, in order.
        case sequence([Self])
    }
}

// MARK: - Conditional Conformances

extension Store.Effect: Sendable where Action: Sendable, Operation: Sendable {}
extension Store.Effect: Equatable where Action: Equatable, Operation: Equatable {}
extension Store.Effect: Hashable where Action: Hashable, Operation: Hashable {}

// MARK: - Composition

extension Store.Effect {
    /// This effect placed side by side with `other`.
    ///
    /// `none` is absorbed and a nested ``merge(_:)`` is flattened, so the result is
    /// associative and unital up to equality rather than only up to interpretation.
    /// A ``sequence(_:)`` node is treated as one participant and keeps its order.
    ///
    /// - Parameter other: The effect to perform alongside this one.
    /// - Returns: An effect performing both, in no guaranteed order.
    public func merged(with other: Self) -> Self {
        switch (self, other) {
        case (.none, _):
            return other

        case (_, .none):
            return self

        case (.merge(let lhs), .merge(let rhs)):
            return .merge(lhs + rhs)

        case (.merge(let lhs), _):
            return .merge(lhs + [other])

        case (_, .merge(let rhs)):
            return .merge([self] + rhs)

        default:
            return .merge([self, other])
        }
    }

    /// This effect followed by `other`.
    ///
    /// `none` is absorbed and a nested ``sequence(_:)`` is flattened, on the same
    /// terms as ``merged(with:)``. A ``merge(_:)`` node is treated as one
    /// participant and keeps its concurrency.
    ///
    /// - Parameter other: The effect to perform after this one.
    /// - Returns: An effect performing this one, then `other`.
    public func followed(by other: Self) -> Self {
        switch (self, other) {
        case (.none, _):
            return other

        case (_, .none):
            return self

        case (.sequence(let lhs), .sequence(let rhs)):
            return .sequence(lhs + rhs)

        case (.sequence(let lhs), _):
            return .sequence(lhs + [other])

        case (_, .sequence(let rhs)):
            return .sequence([self] + rhs)

        default:
            return .sequence([self, other])
        }
    }

    /// The monoid of effects under side-by-side composition.
    ///
    /// Identity is ``none``; the operation is ``merged(with:)``.
    public static var merging: Algebra.Monoid<Self> {
        .init(identity: .none, combining: { $0.merged(with: $1) })
    }

    /// The monoid of effects under ordered composition.
    ///
    /// Identity is ``none``; the operation is ``followed(by:)``.
    public static var sequencing: Algebra.Monoid<Self> {
        .init(identity: .none, combining: { $0.followed(by: $1) })
    }
}

// MARK: - Transformation

extension Store.Effect {
    /// This effect with every action rewritten by `transform`.
    ///
    /// Rewriting actions is how a child's effect becomes its parent's: the child
    /// speaks its own action vocabulary, and the parent embeds it. Operations pass
    /// through untouched.
    ///
    /// - Parameter transform: Rewrites one action.
    /// - Returns: The same effect structure over the rewritten action type.
    /// - Throws: Whatever `transform` throws.
    public func map<Other, Failure: Swift.Error>(
        action transform: (Action) throws(Failure) -> Other
    ) throws(Failure) -> Store.Effect<Other, Operation> {
        switch self {
        case .none:
            return .none

        case .send(let action):
            return .send(try transform(action))

        case .run(let operation):
            return .run(operation)

        case .merge(let effects):
            return .merge(
                try effects.map { (effect: Self) throws(Failure) -> Store.Effect<Other, Operation> in
                    try effect.map(action: transform)
                }
            )

        case .sequence(let effects):
            return .sequence(
                try effects.map { (effect: Self) throws(Failure) -> Store.Effect<Other, Operation> in
                    try effect.map(action: transform)
                }
            )
        }
    }

    /// This effect with every operation rewritten by `transform`.
    ///
    /// Rewriting operations is how a runtime lowers an abstract leaf onto the work
    /// type it actually performs. Actions pass through untouched.
    ///
    /// - Parameter transform: Rewrites one operation.
    /// - Returns: The same effect structure over the rewritten operation type.
    /// - Throws: Whatever `transform` throws.
    public func lower<Other, Failure: Swift.Error>(
        operation transform: (Operation) throws(Failure) -> Other
    ) throws(Failure) -> Store.Effect<Action, Other> {
        switch self {
        case .none:
            return .none

        case .send(let action):
            return .send(action)

        case .run(let operation):
            return .run(try transform(operation))

        case .merge(let effects):
            return .merge(
                try effects.map { (effect: Self) throws(Failure) -> Store.Effect<Action, Other> in
                    try effect.lower(operation: transform)
                }
            )

        case .sequence(let effects):
            return .sequence(
                try effects.map { (effect: Self) throws(Failure) -> Store.Effect<Action, Other> in
                    try effect.lower(operation: transform)
                }
            )
        }
    }
}
