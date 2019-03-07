import PromiseKit6

// for BridgingTests.m
@objc(PMKPromiseBridgeHelper) class PromiseBridgeHelper: NSObject {
    @objc func bridge1() -> AnyPromise {
        let p = after6(.milliseconds(10))
        return AnyPromise(p)
    }
}

enum MyError: Error {
    case PromiseError
}

@objc class TestPromise626: NSObject {

    @objc class func promise() -> AnyPromise {
        let promise: Promise6<String> = Promise6 { seal in
            seal.reject(MyError.PromiseError)
        }

        return AnyPromise(promise)
    }
}
