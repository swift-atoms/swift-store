public import Index
public import Ordinal
public import Tagged

public protocol __StoreProtocol: ~Copyable {

    associatedtype Element: ~Copyable

    var capacity: Index<Element>.Count { get }

    subscript(slot: Index<Element>) -> Element { get set }

    mutating func initialize(at slot: Index<Element>, to element: consuming Element)

    mutating func move(at slot: Index<Element>) -> Element

    /// Destroys the elements in `range` and leaves those slots vacant.
    ///
    /// The default moves each element out in turn. A store that can destroy a run of slots in one pass
    /// provides its own, and generic code reaches it through this requirement.
    mutating func deinitialize(range: Swift.Range<Index<Element>>)

    mutating func swapAt(_ i: Index<Element>, _ j: Index<Element>)

    mutating func unshare()
}

extension __StoreProtocol where Self: ~Copyable {

    @inlinable
    public mutating func unshare() {}
}

extension __StoreProtocol where Self: ~Copyable {

    @inlinable
    public mutating func swapAt(_ i: Index<Element>, _ j: Index<Element>) {
        guard i != j else { return }
        let a = move(at: i)
        let b = move(at: j)
        initialize(at: i, to: b)
        initialize(at: j, to: a)
    }
}

extension Store::Store {

    public typealias `Protocol` = __StoreProtocol
}
