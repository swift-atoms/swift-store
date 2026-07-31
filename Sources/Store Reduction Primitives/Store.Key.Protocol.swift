/// A key naming a typed value that travels between features.
///
/// Conform a type — normally a caseless enum, which cannot be instantiated by
/// accident — and state what the value is and what it is before anyone supplies
/// one. The conforming type *is* the address: nothing is looked up by name, and
/// nothing is matched by reflection, so a key costs nothing at runtime and works
/// where reflection does not exist.
///
/// ## Conformance Requirements
///
/// ```swift
/// enum Theme: Store.Key.Protocol {
///     static var initial: Palette { .system }
/// }
/// ```
///
/// ## Commands Are Values
///
/// A command a subtree may invoke needs no separate kind of key — it is a value
/// whose type is a function:
///
/// ```swift
/// enum Dismiss: Store.Key.Protocol {
///     static var initial: @Sendable () -> Void { {} }
/// }
/// ```
///
/// The initial value doubles as the neutral behaviour, which is why a feature can
/// be built and tested before anything supplies the real one.
///
/// - Note: This protocol is hoisted to module level due to Swift limitations.
///   Use `Store.Key.Protocol` to refer to this type.
public protocol __StoreKeyProtocol {
    /// The type of the value this key names.
    associatedtype Value: Sendable

    /// The value in force before anything supplies one.
    static var initial: Value { get }
}
