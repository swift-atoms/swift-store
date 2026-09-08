import Store
import Testing

@Suite
struct `Store keys expose their supplied initial values` {
    @Suite struct `Store keys retain ordinary initial values and callable command values` {}
    @Suite struct `No store key boundary cases are defined` {}
    enum Palette {}

    enum Dismiss {}

}

extension `Store keys expose their supplied initial values`.Palette: Store::Store.Key.`Protocol` {
    static var initial: Int { 7 }
}

extension `Store keys expose their supplied initial values`.Dismiss: Store::Store.Key.`Protocol` {
    static var initial: @Sendable () -> Int { { 0 } }
}

extension `Store keys expose their supplied initial values`.`Store keys retain ordinary initial values and callable command values` {
    @Test
    func `a plain key reports its initial value`() {
        #expect(`Store keys expose their supplied initial values`.Palette.initial == 7)
    }

    @Test
    func `a command key initial value is callable`() {
        #expect(`Store keys expose their supplied initial values`.Dismiss.initial() == 0)
    }

}
