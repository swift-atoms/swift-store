public import Store_Protocol
public import Index
public import Affine_Standard_Library_Integration
public import Affine_Tagged
public import Cardinal
public import Cardinal_Carrier
public import Cardinal_Tagged
public import Ordinal
public import Ordinal_Protocol
public import Ordinal_Cardinal
public import Ordinal_Standard_Library_Integration
public import Ordinal_Tagged
public import Tagged

extension __StoreProtocol where Self: ~Copyable, Element: Copyable {

    @inlinable
    public mutating func fill(range: Swift.Range<Index<Element>>, with element: borrowing Element) {
        var slot = range.lowerBound
        while slot < range.upperBound {
            initialize(at: slot, to: copy element)
            slot += .one
        }
    }

    @inlinable
    public mutating func fill(with element: borrowing Element) {
        let upper: Index<Element> = capacity.map(Ordinal.init)
        fill(range: .zero..<upper, with: element)
    }
}
