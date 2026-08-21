public protocol __StoreKeyProtocol {

    associatedtype Value: Sendable

    static var initial: Value { get }
}
