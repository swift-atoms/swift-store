# swift-store

Use this package when you are writing or consuming the slot-level contract underneath a container: a fixed number of typed slots that the caller initializes, reads, mutates and moves out of one at a time, for `Copyable` and `~Copyable` elements alike. Start from `Store.Protocol` to write generic code over any such store, `Store.Inline<Element, n>` for slots stored inline with a compile-time capacity, `Store.Split<Lanes, Elements>` to pair a per-slot side plane with the element plane, and `Store.Initialization<Element>` with `Store.Ledgered.Protocol` to record which slots are initialized. For a heap-allocated column, dense or generational, use swift-storage instead; for a container with an ordering or growth policy use a buffer from swift-buffer. The same `Store` namespace also holds the state-transition vocabulary for an app store: `Store.Update<State, Action, Operation>`, `Store.Effect<Action, Operation>` and `Store.Key.Protocol`.

## Laws

`Store.Protocol`:

- A store does not track which slots are initialized. `initialize(at:to:)` requires a vacant slot; the subscript, `move(at:)` and `swapAt(_:_:)` require initialized slots. `move(at:)` leaves the slot vacant and reusable.
- The default `swapAt(_:_:)` does nothing for equal indices and otherwise moves both elements out and initializes each into the other slot. A conformer may replace it.
- The default `unshare()` does nothing.
- `copy(to:count:)` and `fill(range:with:)` work on the slots the caller names and check nothing.
- `copy(to:count:)` initializes the destination's slots `0..<count` from the source's and leaves the source and the destination's other slots untouched.
- `moveInitialize(from:to:count:)` handles overlapping ranges: moving toward higher slots goes back to front, otherwise front to back, and the vacated source slots are left vacant. A zero count or equal positions do nothing, as does `move(from:to:)` with equal positions.
- `deinitialize(at:)` and `deinitialize(range:)` move each element out and destroy it, exactly once.

`Store.Initialization<Element>` and `Store.Ledgered.Protocol`:

- A ledger names at most two disjoint initialized ranges. `forEach(_:)` visits `first` then `second`; `linearize(_:)` passes each range with the sum of the counts of the ranges before it. `linear(count:)` of zero is `.empty`.
- `inserting(_:)` and `removing(_:)` give the ledger after one slot becomes initialized or vacant; they trap when the slot is already in that state or the result would need a third range.
- Nothing in `Store.Ledgered.Protocol` keeps `initialization` in step with the slots; the conformer or its owner does.
- The whole-store operations are defined only on a ledgered store and visit exactly the slots its ledger names, `first` then `second`, each in ascending order: `forEach(_:)`, `reduce(into:_:)`, `contains(where:)`, `contains(_:)`, `copy(to:)` (into the same slots of the destination), `clear()` and `removeAll()` (which leave the ledger `.empty`). A thrown error stops before any later slot and leaves the store unchanged; `contains` stops at the first match. `fill(with:)` requires an empty ledger, initializes every slot and sets the ledger to `0..<capacity`.

`Store.Inline<Element, n>`:

- Destroying it deinitializes exactly the ranges its `initialization` names, and nothing else.
- `initialize(at:to:)` and `move(at:)` derive the ledger from the slot through `inserting(_:)` and `removing(_:)`, so it names exactly the initialized slots at any position, and they trap on a slot in the wrong state or a pattern needing three ranges. An owner may still overwrite `initialization` with a shape it knows to be true.
- `swapAt(_:_:)` exchanges the two elements in place, requires both slots initialized and leaves the ledger unchanged.
- The subscript does not check the slot against the capacity or the ledger, and no operation checks the slot against the capacity.

`Store.Split<Lanes, Elements>`:

- Every `Store.Protocol` operation, including `capacity` and `swapAt(_:_:)` with equal indices, goes to the element plane only; the lane plane changes only through `lanes`. `unshare()` unshares both planes.

`Store.Effect<Action, Operation>`:

- `merged(with:)` and `followed(by:)` are associative and have `.none` as a two-sided identity. Each flattens its own kind (`.merge` into `.merge`, `.sequence` into `.sequence`) and keeps the other kind whole as a single element. An empty `.merge([])` or `.sequence([])` is not `.none`: combining `.send` with an empty merge gives a one-element merge.
- `map(action:)` rewrites every `.send` and `lower(operation:)` every `.run`, preserving the structure; mapping with the identity changes nothing and two maps equal one fused map. A thrown error from the transform propagates; the transform is never called for an effect with no `.send`.
- The package never runs an effect; whatever interprets `.merge` and `.sequence` gives them their meaning.
- With the Algebra trait, `Store.Effect.merging` and `Store.Effect.sequencing` are those combinators as monoids with identity `.none`.

`Store.Update<State, Action, Operation>`:

- `combined(with:)` runs `self` and then `other` on the same state, so `other` sees `self`'s changes; the result is `self`'s effect merged with `other`'s. `empty` changes nothing and returns `.none`, and is a two-sided identity; combining is associative. `init(_:)` with an array combines its elements in order and is `empty` when the array is empty. With the Algebra trait, `Store.Update.combining` is this monoid.
- `optional` does nothing and returns `.none` when the state is `nil`.
- With the Optic trait, `lift(state:action:)` does nothing and returns `.none` for a message the prism does not extract. Otherwise it reads the part through the lens, runs the update, writes the part back through the lens, and embeds every `.send` of the effect through the prism; `.run` operations pass through.

`Store.Key.Protocol`:

- With the Algebra trait, a `Store.Key.Aggregate` key's `initial` defaults to the identity of its `aggregation`, and `aggregation` must be a lawful monoid: associative with a two-sided identity.
