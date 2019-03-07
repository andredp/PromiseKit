import Dispatch

/**
 Judicious use of `firstly` *may* make chains more readable.

 Compare:

     URLSession.shared.dataTask(url: url1).then {
         URLSession.shared.dataTask(url: url2)
     }.then {
         URLSession.shared.dataTask(url: url3)
     }

 With:

     firstly {
         URLSession.shared.dataTask(url: url1)
     }.then {
         URLSession.shared.dataTask(url: url2)
     }.then {
         URLSession.shared.dataTask(url: url3)
     }

 - Note: the block you pass excecutes immediately on the current thread/queue.
 */
public func firstly6<U: Thenable6>(execute body: () throws -> U) -> Promise6<U.T> {
    do {
        let rp = Promise6<U.T>(.pending)
        try body().pipe(to: rp.box.seal)
        return rp
    } catch {
        return Promise6(error: error)
    }
}

/// - See: firstly()
public func firstly<T>(execute body: () -> Guarantee6<T>) -> Guarantee6<T> {
    return body()
}
