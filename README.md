# swift-store

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

The pure reduction algebra of the state architecture — the update that advances state, the effect it asks for, and the keys features address one another by. Nothing here runs: every value in this package is data that a store runtime interprets.

---

## Key Features

- **A total update** — `Store.Update` advances state in place and returns the work it wants done. It does not throw: a failure the domain cares about is an action fed back into the store, which is what keeps a reduction replayable.
- **Effects as data** — `Store.Effect` is a five-case value, not a computation. Producing one performs nothing.
- **The work leaf is yours** — the effect's `Operation` type is a generic parameter this package never inspects, so the runtime decides what work means. Cancellation is an operation like any other and needs no case of its own.
- **Composition with laws, not conventions** — merging and sequencing are associative with `none` as a two-sided identity, verified as laws rather than asserted in prose. The `Algebra.Monoid` witnesses live in [swift-store-algebra](https://github.com/swift-molecules/swift-store-algebra).
- **Scoping without reflection** — `optional` moves an update over optional state; `lift(state:action:)`, which scopes an update into a wider domain through an `Optic.Lens` and `Optic.Prism`, lives in [swift-store-optic](https://github.com/swift-molecules/swift-store-optic).
- **Typed communication keys** — `Store.Key.Protocol` names a value travelling downward; `Store.Key.Aggregate`, the key whose contributions combine under a monoid, lives in [swift-store-algebra](https://github.com/swift-molecules/swift-store-algebra). The conforming type is the address, so nothing is matched by name or by reflection.
- **Deployable where reflection is not** — no reflection, no Objective-C interop, no metatype identity, no Foundation, no locks.

---

## Quick Start

An update advances state and describes what it wants done. Composing and scoping updates is how a feature becomes part of a larger one:

```swift
import Store

enum Counter: Equatable { case increment, decrement }
enum Job: Equatable { case beacon }

let counter = Store.Update<Int, Counter, Job> { count, action in
    switch action {
    case .increment:
        count += 1
        return .run(.beacon)

    case .decrement:
        count -= 1
        return .none
    }
}

var count = 0
let effect = counter.effect(for: .increment, in: &count)
// count  == 1
// effect == .run(.beacon)
```

Effects compose two ways, and the two do not mix — side by side, or in order:

```swift
let both = Store.Effect<Counter, Job>.run(.beacon)
    .followed(by: .send(.decrement))
    .merged(with: .run(.beacon))
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-molecules/swift-store.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Store", package: "swift-store")
    ]
)
```

Requires Swift 6.3.3. Platform minimums: macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26.

---

## Architecture

Three library products in the canonical atom shape.

| Product | When to import |
|---------|----------------|
| `Store` | Declaring updates, effects, and communication keys in library or application code. |
| `Store Standard Library Integration` | Conformances and extensions integrating `Store` with the Swift standard library. |
| `Store Apple Foundation Integration` | Integration with Apple Foundation; the only module that imports Foundation. |

Integration with `Algebra Monoid` lives in [swift-store-algebra](https://github.com/swift-molecules/swift-store-algebra); integration with `Optic` lives in [swift-store-optic](https://github.com/swift-molecules/swift-store-optic).

Key types in the `Store` namespace:

| Type | Purpose |
|------|---------|
| `Store.Update` | Advances state in place by one action and returns the work requested. |
| `Store.Effect` | The description of that work: `none`, `send`, `run`, `merge`, `sequence`. |
| `Store.Key.\`Protocol\`` | A typed key naming a value that travels down the store tree — including a command, which is a value whose type is a function. |

The runtime that interprets these values — the store itself, feature lifecycle, isolation, and
test support — lives in [swift-stores](https://github.com/swift-compositions/swift-stores).

---

## Design Attribution

An independent implementation in the Elm lineage. The vocabulary of a store advanced by actions descends from Elm and Redux; the shape of a reducer returning effects as data is prior art visible in the MIT-licensed [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture), including its public 2.0 beta. No code or API surface from any of those is reproduced here.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public release.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
