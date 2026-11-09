public import Cardinal
import Difference
public import Index
public import Ordinal
public import Tagged

extension Store::Store.Inline where Element: ~Copyable {

    @inlinable
    public var capacity: Index<Element>.Count { Index<Element>.Count(UInt(n)) }

    @inlinable
    public var count: Index<Element>.Count { _initialization.count }

    @inlinable
    public var isEmpty: Bool { _initialization.isEmpty }

    @inlinable
    public var initialization: Store::Store.Initialization<Element> {
        get { _initialization }
        set { _initialization = newValue }
    }
}

extension Store::Store.Inline where Element: ~Copyable {

    @inlinable
    package func _readBase() -> UnsafePointer<Element> {
        withUnsafePointer(to: _storage) {
            unsafe UnsafeRawPointer($0).assumingMemoryBound(to: Element.self)
        }
    }

    @inlinable
    package mutating func _mutableBase() -> UnsafeMutablePointer<Element> {
        withUnsafeMutablePointer(to: &_storage) {
            unsafe UnsafeMutableRawPointer($0).assumingMemoryBound(to: Element.self)
        }
    }
}

extension Store::Store.Inline where Element: ~Copyable {

    @inlinable
    public subscript(slot: Index<Element>) -> Element {
        _read {
            let pointer = unsafe _readBase() + Index<Element>.Offset(fromZero: slot)
            yield unsafe pointer.pointee
        }
        _modify {
            let pointer = unsafe _mutableBase() + Index<Element>.Offset(fromZero: slot)
            yield &(unsafe pointer.pointee)
        }
    }

    @inlinable
    public mutating func initialize(at slot: Index<Element>, to element: consuming Element) {
        let initialization = _initialization.inserting(slot)
        let pointer = unsafe _mutableBase() + Index<Element>.Offset(fromZero: slot)
        unsafe pointer.initialize(to: element)
        _initialization = initialization
    }

    @inlinable
    public mutating func move(at slot: Index<Element>) -> Element {
        _initialization = _initialization.removing(slot)
        return withUnsafeMutablePointer(to: &_storage) { raw -> Element in
            let base = unsafe UnsafeMutableRawPointer(raw).assumingMemoryBound(to: Element.self)
            let pointer = unsafe base + Index<Element>.Offset(fromZero: slot)
            return unsafe pointer.move()
        }
    }

    @inlinable
    public mutating func swapAt(_ i: Index<Element>, _ j: Index<Element>) {
        precondition(
            _initialization.contains(i) && _initialization.contains(j),
            "Store.Inline.swapAt(_:_:): both slots must be initialized"
        )
        guard i != j else { return }
        withUnsafeMutablePointer(to: &_storage) { raw in
            let base = unsafe UnsafeMutableRawPointer(raw).assumingMemoryBound(to: Element.self)
            let first = unsafe base + Index<Element>.Offset(fromZero: i)
            let second = unsafe base + Index<Element>.Offset(fromZero: j)
            let element = unsafe first.move()
            unsafe first.moveInitialize(from: second, count: 1)
            unsafe second.initialize(to: element)
        }
    }
}

extension Store::Store.Inline: Store::Store.`Protocol` where Element: ~Copyable {}
