public import Algebra_Monoid_Primitives

extension Store {

    public enum Effect<Action, Operation> {

        case none

        case send(Action)

        case run(Operation)

        case merge([Self])

        case sequence([Self])
    }
}

extension Store.Effect: Sendable where Action: Sendable, Operation: Sendable {}
extension Store.Effect: Equatable where Action: Equatable, Operation: Equatable {}
extension Store.Effect: Hashable where Action: Hashable, Operation: Hashable {}

extension Store.Effect {

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

    public static var merging: Algebra.Monoid<Self> {
        .init(identity: .none, combining: { $0.merged(with: $1) })
    }

    public static var sequencing: Algebra.Monoid<Self> {
        .init(identity: .none, combining: { $0.followed(by: $1) })
    }
}

extension Store.Effect {

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
                try effects.map {
                    (effect: Self) throws(Failure) -> Store.Effect<Other, Operation> in
                    try effect.map(action: transform)
                }
            )

        case .sequence(let effects):
            return .sequence(
                try effects.map {
                    (effect: Self) throws(Failure) -> Store.Effect<Other, Operation> in
                    try effect.map(action: transform)
                }
            )
        }
    }

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
