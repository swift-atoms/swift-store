# swift-store

`swift-store` owns the `Store` domain: its namespace, reduction values, storage
protocols and operations, initialization ledger, and concrete Store policies.

Products are intentionally focused:

- `Store` — `Store.Update`, `Store.Effect`, and `Store.Key.Protocol`.
- `Store Protocol` — the abstract indexed Store capability.
- `Store Operations` — copy, move, fill, deinitialize, and sequence operations.
- `Store Initialization` — initialized-slot ledger values.
- `Store Ledgered` — Store protocols that expose an initialization ledger.
- `Store Inline` — fixed-capacity inline Store implementation.
- `Store Split` — a Store composed from independent lane and element stores.
- `Store Generational` — the generational namespace and handle value.

Algebra and optic integrations remain in `swift-store-algebra` and
`swift-store-optic`. This package has no dependency on `swift-storage`.

```swift
.package(url: "https://github.com/swift-atoms/swift-store.git", branch: "main")
```

Choose only the products a target imports. For example:

```swift
.product(name: "Store Protocol", package: "swift-store")
```

Apache 2.0. See [LICENSE.md](LICENSE.md).
