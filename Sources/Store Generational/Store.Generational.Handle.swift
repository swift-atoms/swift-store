public import Store

extension Store::Store.Generational {

    @frozen
    public struct Handle: Hashable, Sendable {

        public let index: Int

        public let generation: Int
        @inlinable
        public init(index: Int, generation: Int) {
            self.index = index
            self.generation = generation
        }
    }
}
