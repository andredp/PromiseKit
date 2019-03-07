import Dispatch

enum Sealant6<R> {
    case pending(Handlers6<R>)
    case resolved(R)
}

final class Handlers6<R> {
    var bodies: [(R) -> Void] = []
    func append(_ item: @escaping(R) -> Void) { bodies.append(item) }
}

/// - Remark: not protocol ∵ http://www.russbishop.net/swift-associated-types-cont
class Box6<T> {
    func inspect() -> Sealant6<T> { fatalError() }
    func inspect(_: (Sealant6<T>) -> Void) { fatalError() }
    func seal(_: T) {}
}

final class SealedBox6<T>: Box6<T> {
    let value: T

    init(value: T) {
        self.value = value
    }

    override func inspect() -> Sealant6<T> {
        return .resolved(value)
    }
}

class EmptyBox6<T>: Box6<T> {
    private var sealant = Sealant6<T>.pending(.init())
    private let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)

    override func seal(_ value: T) {
        var handlers: Handlers6<T>!
        barrier.sync(flags: .barrier) {
            guard case .pending(let _handlers) = self.sealant else {
                return  // already fulfilled!
            }
            handlers = _handlers
            self.sealant = .resolved(value)
        }

        //FIXME we are resolved so should `pipe(to:)` be called at this instant, “thens are called in order” would be invalid
        //NOTE we don’t do this in the above `sync` because that could potentially deadlock
        //THOUGH since `then` etc. typically invoke after a run-loop cycle, this issue is somewhat less severe

        if let handlers = handlers {
            handlers.bodies.forEach{ $0(value) }
        }

        //TODO solution is an unfortunate third state “sealed” where then's get added
        // to a separate handler pool for that state
        // any other solution has potential races
    }

    override func inspect() -> Sealant6<T> {
        var rv: Sealant6<T>!
        barrier.sync {
            rv = self.sealant
        }
        return rv
    }

    override func inspect(_ body: (Sealant6<T>) -> Void) {
        var sealed = false
        barrier.sync(flags: .barrier) {
            switch sealant {
            case .pending:
                // body will append to handlers, so we must stay barrier’d
                body(sealant)
            case .resolved:
                sealed = true
            }
        }
        if sealed {
            // we do this outside the barrier to prevent potential deadlocks
            // it's safe because we never transition away from this state
            body(sealant)
        }
    }
}


extension Optional where Wrapped: DispatchQueue {
    @inline(__always)
    func async(flags: DispatchWorkItemFlags?, _ body: @escaping() -> Void) {
        switch self {
        case .none:
            body()
        case .some(let q):
            if let flags = flags {
                q.async(flags: flags, execute: body)
            } else {
                q.async(execute: body)
            }
        }
    }
}
