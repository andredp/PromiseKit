import class Foundation.Thread
import Dispatch

/**
 A `Promise` is a functional abstraction around a failable asynchronous operation.
 - See: `Thenable`
 */
public final class Promise6<T>: Thenable6, CatchMixin6 {
    let box: Box6<Result<T>>

    fileprivate init(box: SealedBox6<Result<T>>) {
        self.box = box
    }

    /**
      Initialize a new fulfilled promise.

      We do not provide `init(value:)` because Swift is “greedy”
      and would pick that initializer in cases where it should pick
      one of the other more specific options leading to Promises with
      `T` that is eg: `Error` or worse `(T->Void,Error->Void)` for
      uses of our PMK < 4 pending initializer due to Swift trailing
      closure syntax (nothing good comes without pain!).

      Though often easy to detect, sometimes these issues would be
      hidden by other type inference leading to some nasty bugs in
      production.

      In PMK5 we tried to work around this by making the pending
      initializer take the form `Promise(.pending)` but this led to
      bad migration errors for PMK4 users. Hence instead we quickly
      released PMK6 and now only provide this initializer for making
      sealed & fulfilled promises.

      Usage is still (usually) good:

          guard foo else {
              return .value(bar)
          }
     */
    public class func value(_ value: T) -> Promise6<T> {
        return Promise6(box: SealedBox6(value: .fulfilled(value)))
    }

    /// Initialize a new rejected promise.
    public init(error: Error) {
        box = SealedBox6(value: .rejected(error))
    }

    /// Initialize a new promise bound to the provided `Thenable`.
    public init<U: Thenable6>(_ bridge: U) where U.T == T {
        box = EmptyBox6()
        bridge.pipe(to: box.seal)
    }

    /// Initialize a new promise that can be resolved with the provided `Resolver`.
    public init(resolver body: (Resolver6<T>) throws -> Void) {
        box = EmptyBox6()
        let resolver = Resolver6(box)
        do {
            try body(resolver)
        } catch {
            resolver.reject(error)
        }
    }

    /// - Returns: a tuple of a new pending promise and its `Resolver`.
    public class func pending() -> (promise: Promise6<T>, resolver: Resolver6<T>) {
        return { ($0, Resolver6($0.box)) }(Promise6<T>(.pending))
    }

    /// - See: `Thenable.pipe`
    public func pipe(to: @escaping(Result<T>) -> Void) {
        switch box.inspect() {
        case .pending:
            box.inspect {
                switch $0 {
                case .pending(let handlers):
                    handlers.append(to)
                case .resolved(let value):
                    to(value)
                }
            }
        case .resolved(let value):
            to(value)
        }
    }

    /// - See: `Thenable.result`
    public var result: Result<T>? {
        switch box.inspect() {
        case .pending:
            return nil
        case .resolved(let result):
            return result
        }
    }

    init(_: PMKUnambiguousInitializer) {
        box = EmptyBox6()
    }
}

public extension Promise6 {
    /**
     Blocks this thread, so—you know—don’t call this on a serial thread that
     any part of your chain may use. Like the main thread for example.
     */
    func wait() throws -> T {

        if Thread.isMainThread {
            conf.logHandler(LogEvent6.waitOnMainThread)
        }

        var result = self.result

        if result == nil {
            let group = DispatchGroup()
            group.enter()
            pipe { result = $0; group.leave() }
            group.wait()
        }

        switch result! {
        case .rejected(let error):
            throw error
        case .fulfilled(let value):
            return value
        }
    }
}

#if swift(>=3.1)
extension Promise6 where T == Void {
    /// Initializes a new promise fulfilled with `Void`
    public convenience init() {
        self.init(box: SealedBox6(value: .fulfilled(Void())))
    }
}
#endif


public extension DispatchQueue {
    /**
     Asynchronously executes the provided closure on a dispatch queue.

         DispatchQueue.global().async(.promise) {
             try md5(input)
         }.done { md5 in
             //…
         }

     - Parameter body: The closure that resolves this promise.
     - Returns: A new `Promise` resolved by the result of the provided closure.
     - Note: There is no Promise/Thenable version of this due to Swift compiler ambiguity issues.
     */
    @available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
    final func async<T>(_: PMKNamespacer, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], execute body: @escaping () throws -> T) -> Promise6<T> {
        let promise = Promise6<T>(.pending)
        async(group: group, qos: qos, flags: flags) {
            do {
                promise.box.seal(.fulfilled(try body()))
            } catch {
                promise.box.seal(.rejected(error))
            }
        }
        return promise
    }
}


/// used by our extensions to provide unambiguous functions with the same name as the original function
public enum PMKNamespacer {
    case promise
}

enum PMKUnambiguousInitializer {
    case pending
}
