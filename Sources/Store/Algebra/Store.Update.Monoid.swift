#if Algebra
public import Algebra

extension Store::Store.Update {

    public static var combining: Algebra.Monoid<Self> {
        .init(identity: .empty, combining: { $0.combined(with: $1) })
    }
}
#endif
