import Foundation

/// A lock-guarded holder for a value that has to be reachable from contexts
/// with different isolation.
///
/// The continuations driving ``TagScanner`` and ``TagWriter`` are handed out on
/// the main actor but must also be resumed from `deinit`, which is never actor
/// isolated. Guarding them with a lock rather than an actor keeps that path
/// available.
///
/// `@unchecked Sendable` is warranted here because `NSLock` provides the
/// synchronization the compiler cannot verify on its own.
final class LockedBox<Value>: @unchecked Sendable {

    private let lock = NSLock()

    private var value: Value?

    init(_ value: Value? = nil) {
        self.value = value
    }

    /// The current value, if it has not already been taken.
    var current: Value? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ newValue: Value?) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }

    /// Atomically removes and returns the value, guaranteeing that only one
    /// caller ever observes it. Continuations must be resumed exactly once, so
    /// every resume path goes through this.
    func take() -> Value? {
        lock.lock()
        defer { lock.unlock() }
        let taken = value
        value = nil
        return taken
    }
}
