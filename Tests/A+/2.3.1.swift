import PromiseKit
import XCTest

class Test231: XCTestCase {
    func test() {
        describe("2.3.1: If `promise` and `x` refer to the same object, reject `promise` with a `TypeError' as the reason.") {
            specify("via return from a fulfilled promise") { d, expectation in
                var promise: Promise6<Void>!
                promise = Promise6().then { () -> Promise6<Void> in
                    return promise
                }
                promise.catch { err in
                    if case PMKError.returnedSelf = err {
                        expectation.fulfill()
                    }
                }
            }
            specify("via return from a rejected promise") { d, expectation in
                var promise: Promise6<Void>!
                promise = Promise6<Void>(error: Error.dummy).recover { _ -> Promise6<Void> in
                    return promise
                }
                promise.catch { err in
                    if case PMKError.returnedSelf = err {
                        expectation.fulfill()
                    }
                }
            }
        }
    }
}
