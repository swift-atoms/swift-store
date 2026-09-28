#if Algebra
public import Algebra

extension Store::Store.Effect {

    public static var merging: Algebra.Monoid<Self> {
        .init(identity: .none, combining: { $0.merged(with: $1) })
    }

    public static var sequencing: Algebra.Monoid<Self> {
        .init(identity: .none, combining: { $0.followed(by: $1) })
    }
}
#endif
