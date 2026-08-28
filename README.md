# swift-store

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

The pure reduction algebra of the state architecture — the update that advances state, the effect it asks for, and the keys features address one another by. Nothing here runs: every value in this package is data that a store runtime interprets.

---

## Key Features

- **A total update** — `Store.Update` advances state in place and returns the work it wants done. It does not throw: a failure the domain cares about is an action fed back into the store, which is what keeps a reduction replayable.
- **Effects as data** — `Store.Effect` is a five-case value, not a computation. Producing one performs nothing.
- **The work leaf is yours** — the effect's `Operation` type is a generic parameter this package never inspects, so the runtime decides what work means. Cancellation is an operation like any other and needs no case of its own.
- **Composition with laws, not conventions** — merging and sequencing each form a monoid with `none` as identity, published as `Algebra.Monoid` witnesses and verified as laws rather than asserted in prose.
- **Scoping without reflection** — `lift(state:action:)` moves an update into a wider domain, taking an `Optic.Lens` onto the wider state and an `Optic.Prism` onto the wider message. A message the prism does not recognise leaves the state untouched. Scoping *is* a lens and a prism, so it is spelled with the ecosystem's optics rather than re-stating them as loose functions.
- **Typed communication keys** — `Store.Key.Protocol` names a value travelling downward; `Store.Key.Aggregate` adds the monoid that combines contributions travelling upward. The conforming type is the address, so nothing is matched by name or by reflection.
- **Deployable where reflection is not** — no reflection, no Objective-C interop, no metatype identity, no Foundation, no locks.

---

## Quick Start

An update advances state and describes what it wants done. Composing and scoping updates is how a feature becomes part of a larger one:

```swift
import Store_Reduction

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
        .product(name: "Store Reduction", package: "swift-store")
    ]
)
```

Requires Swift 6.3.3. Platform minimums: macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26.

---

## Architecture

Two library products over a single source module.

| Product | When to import |
|---------|----------------|
| `Store Reduction` | Declaring updates, effects, and communication keys in library or application code. |
| `Store Reduction Test Support` | Test targets exercising reductions; re-exports the main module alongside `Algebra Monoid` and `Optic`. |

The module is named `Store Reduction` rather than `Store Primitives` because
[swift-storage](https://github.com/swift-molecules/swift-storage) already
publishes a `Store Primitives` product for the physical element-store substrate, and both
packages appear in the same dependency closure.

Key types in the `Store` namespace:

| Type | Purpose |
|------|---------|
| `Store.Update` | Advances state in place by one action and returns the work requested. |
| `Store.Effect` | The description of that work: `none`, `send`, `run`, `merge`, `sequence`. |
| `Store.Key.\`Protocol\`` | A typed key naming a value that travels down the store tree — including a command, which is a value whose type is a function. |
| `Store.Key.Aggregate` | A typed key whose contributions travel up and combine under a monoid. |

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
