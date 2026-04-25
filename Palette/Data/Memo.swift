import Foundation

// Single-slot memoization keyed by an input hash.
//
// Designed for use inside SwiftUI body computations, which run on the
// main actor - that single-threaded usage is what makes the bare class
// safe without an explicit lock. Do not access from background threads.
final class Memo<Key: Hashable, Value> {
    private var key: Key?
    private var value: Value?

    func get(_ k: Key, build: () -> Value) -> Value {
        if let cached = value, k == key {
            return cached
        }
        let v = build()
        key = k
        value = v
        return v
    }
}
