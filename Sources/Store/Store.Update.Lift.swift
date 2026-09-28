#if Optic
@_exported public import Optic

extension Store.Update {

    public func lift<Whole, Message>(
        state: Optic<Whole, Whole, State, State>.SendableLens,
        action: Optic<Message, Message, Action, Action>.SendablePrism
    ) -> Store.Update<Whole, Message, Operation> {
        .init { whole, message in
            guard let inner = action.extract(message) else { return .none }
            var part = state.get(whole)
            let effect = self.transition(&part, inner)
            whole = state.set(whole, part)
            return effect.map(action: action.embed)
        }
    }
}
#endif
