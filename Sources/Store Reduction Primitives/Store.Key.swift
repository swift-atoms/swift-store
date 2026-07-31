extension Store {
    /// Namespace for the keys features address one another by.
    ///
    /// A key is a type. It names a value that travels between features without the
    /// sender and the receiver knowing about one another, and it carries the value's
    /// type with it, so the traffic is checked at compile time rather than matched
    /// by string at runtime.
    ///
    /// Two kinds exist, split on the invariant each upholds:
    ///
    /// - ``Store/Key/Protocol`` carries a value and an initial value. It serves
    ///   traffic that flows down a store tree — a value a subtree may read, or a
    ///   command it may invoke. A command needs no separate kind: it is a value
    ///   whose type is a function.
    /// - ``Store/Key/Aggregate`` adds a monoid, so many contributions combine into
    ///   one. It serves traffic that flows up.
    ///
    /// Direction is deliberately not encoded in the key. Which way a value travels
    /// is a property of the edge a runtime carries it across, not of the key itself;
    /// what distinguishes the two kinds is whether contributions must combine.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Theme: Store.Key.Protocol {
    ///     static var initial: Palette { .system }
    /// }
    ///
    /// enum Warnings: Store.Key.Aggregate {
    ///     typealias Value = [Warning]
    ///
    ///     static var aggregation: Algebra.Monoid<[Warning]> {
    ///         .init(identity: [], combining: +)
    ///     }
    /// }
    /// ```
    public enum Key {
        /// A key naming a typed value with an initial value.
        ///
        /// Use `Store.Key.Protocol` to refer to this type.
        public typealias `Protocol` = __StoreKeyProtocol

        /// A key whose contributions combine under a monoid.
        ///
        /// Use `Store.Key.Aggregate` to refer to this type.
        public typealias Aggregate = __StoreKeyAggregateProtocol
    }
}
