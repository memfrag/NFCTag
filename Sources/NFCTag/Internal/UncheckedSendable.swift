import Foundation

/// Carries a non-Sendable value across an isolation boundary.
///
/// The reader session hands non-Sendable CoreNFC objects to its delegate and
/// the work for them has to continue in a `Task`. CoreNFC carries no
/// concurrency annotations, so the compiler cannot establish that those objects
/// are confined to the session's serial queue and never touched elsewhere.
///
/// `nonisolated(unsafe)` local bindings express the same thing, but only newer
/// compilers accept them in this position. This wrapper behaves the same way
/// under Swift 6.0, which is the minimum the package supports.
///
/// > Important: Only sound when the wrapped value really is handed over rather
/// than shared. Every use in this package wraps an object the session has just
/// delivered to a single callback.
struct UncheckedSendable<Value>: @unchecked Sendable {

    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}
