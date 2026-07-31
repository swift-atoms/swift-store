public import Algebra_Monoid_Primitives

/// A key whose contributions combine under a monoid.
///
/// Where a plain ``Store/Key/Protocol`` names one value in force, an aggregate key
/// names many contributions that must become one. Supplying the monoid rather than
/// a bare combining function is what makes the result independent of the order the
/// contributions are gathered in, and it supplies the initial value for free: with
/// no contributors at all, the answer is the monoid's identity.
///
/// ## Conformance Requirements
///
/// ```swift
/// enum Warnings: Store.Key.Aggregate {
///     static var aggregation: Algebra.Monoid<[Warning]> {
///         .init(identity: [], combining: +)
///     }
/// }
/// ```
///
/// ``__StoreKeyProtocol/initial`` is defaulted to `aggregation.identity`; a
/// conforming type that states its own initial value is asserting something the
/// monoid already says, and the two can then disagree.
///
/// - Note: This protocol is hoisted to module level due to Swift limitations.
///   Use `Store.Key.Aggregate` to refer to this type.
public protocol __StoreKeyAggregateProtocol: __StoreKeyProtocol {
    /// The monoid under which contributions combine.
    static var aggregation: Algebra.Monoid<Value> { get }
}

extension __StoreKeyAggregateProtocol {
    /// The value in force with no contributors: the monoid's identity.
    public static var initial: Value {
        aggregation.identity
    }
}
