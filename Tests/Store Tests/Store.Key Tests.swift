import Store
import Testing

@Suite
struct `Store.Key Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    enum Palette {}

    enum Dismiss {}

}

extension `Store.Key Tests`.Palette: Store::Store.Key.`Protocol` {
    static var initial: Int { 7 }
}

extension `Store.Key Tests`.Dismiss: Store::Store.Key.`Protocol` {
    static var initial: @Sendable () -> Int { { 0 } }
}

extension `Store.Key Tests`.Unit {
    @Test
    func `a plain key reports its initial value`() {
        #expect(`Store.Key Tests`.Palette.initial == 7)
    }

    @Test
    func `a command key initial value is callable`() {
        #expect(`Store.Key Tests`.Dismiss.initial() == 0)
    }

}
