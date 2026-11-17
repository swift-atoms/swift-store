# swift-store

Use this package when you are writing or consuming the slot-level contract underneath a container: a fixed number of typed slots that the caller initializes, reads, mutates and moves out of one at a time, for `Copyable` and `~Copyable` elements alike. Start from `Store.Protocol` to write generic code over any such store, `Store.Inline<Element, n>` for slots stored inline with a compile-time capacity, `Store.Split<Lanes, Elements>` to pair a per-slot side plane with the element plane, and `Store.Initialization<Element>` with `Store.Ledgered.Protocol` to record which slots are initialized. For a heap-allocated column, dense or generational, use swift-storage instead; for a container with an ordering or growth policy use a buffer from swift-buffer.

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
