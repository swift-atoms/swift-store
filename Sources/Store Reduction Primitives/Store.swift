/// Namespace for the pure reduction algebra of the state architecture.
///
/// A store holds state and advances it by applying actions. This package owns the
/// part of that idea which is pure: what an update *is*, what an update may *ask
/// for*, and how features *address* one another. Nothing here runs, schedules, or
/// synchronizes anything — a store runtime interprets these values.
///
/// ## Core Concepts
///
/// - ``Store/Update`` is the transition: it advances state in place and returns a
///   description of the work it wants done.
/// - ``Store/Effect`` is that description — a value, not a computation. Its leaf is
///   a generic parameter, so the interpreter chooses what "work" means.
/// - ``Store/Key`` addresses a value that travels between features, downward as a
///   value or a command, upward as an aggregation.
///
/// ## Example
///
/// ```swift
/// enum Action { case increment, decrement }
///
/// let update = Store.Update<Int, Action, Never> { count, action in
///     switch action {
///     case .increment: count += 1
///     case .decrement: count -= 1
///     }
///     return .none
/// }
///
/// var count = 0
/// _ = update.effect(for: .increment, in: &count)  // count == 1
/// ```
///
/// ## Design Attribution
///
/// An independent implementation in the Elm lineage. The vocabulary of a store
/// advanced by actions descends from Elm and Redux; the shape of a reducer that
/// returns effects as data is prior art visible in the MIT-licensed
/// swift-composable-architecture and its public 2.0 beta. No code or API surface
/// from any of those is reproduced here.
public enum Store {}
