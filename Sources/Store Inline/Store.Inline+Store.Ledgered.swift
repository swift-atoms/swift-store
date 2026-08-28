public import Store
public import Store_Ledgered

extension Store::Store.Inline: Store::Store.Ledgered.`Protocol` where Element: ~Copyable {}
