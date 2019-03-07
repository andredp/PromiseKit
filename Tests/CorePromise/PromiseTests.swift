import PromiseKit
import Dispatch
import XCTest

class PromiseTests: XCTestCase {
    func testIsPending() {
        XCTAssertTrue(Promise6<Void>.pending().promise.isPending)
        XCTAssertFalse(Promise6().isPending)
        XCTAssertFalse(Promise6<Void>(error: Error.dummy).isPending)
    }

    func testIsResolved() {
        XCTAssertFalse(Promise6<Void>.pending().promise.isResolved)
        XCTAssertTrue(Promise6().isResolved)
        XCTAssertTrue(Promise6<Void>(error: Error.dummy).isResolved)
    }

    func testIsFulfilled() {
        XCTAssertFalse(Promise6<Void>.pending().promise.isFulfilled)
        XCTAssertTrue(Promise6().isFulfilled)
        XCTAssertFalse(Promise6<Void>(error: Error.dummy).isFulfilled)
    }

    func testIsRejected() {
        XCTAssertFalse(Promise6<Void>.pending().promise.isRejected)
        XCTAssertTrue(Promise6<Void>(error: Error.dummy).isRejected)
        XCTAssertFalse(Promise6().isRejected)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatchQueueAsyncExtensionReturnsPromise() {
        let ex = expectation(description: "")

        DispatchQueue.global().async(.promise) { () -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }.done { one in
            XCTAssertEqual(one, 1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    func testDispatchQueueAsyncExtensionCanThrowInBody() {
        let ex = expectation(description: "")

        DispatchQueue.global().async(.promise) { () -> Int in
            throw Error.dummy
        }.done { _ in
            XCTFail()
        }.catch { _ in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCustomStringConvertible() {
        XCTAssertEqual(Promise6<Int>.pending().promise.debugDescription, "Promise<Int>.pending(handlers: 0)")
        XCTAssertEqual(Promise6().debugDescription, "Promise<()>.fulfilled(())")
        XCTAssertEqual(Promise6<String>(error: Error.dummy).debugDescription, "Promise<String>.rejected(Error.dummy)")

        XCTAssertEqual("\(Promise6<Int>.pending().promise)", "Promise(…Int)")
        XCTAssertEqual("\(Promise6.value(3))", "Promise(3)")
        XCTAssertEqual("\(Promise6<Void>(error: Error.dummy))", "Promise(dummy)")
    }

    func testCannotFulfillWithError() {

        // sadly this test proves the opposite :(
        // left here so maybe one day we can prevent instantiation of `Promise<Error>`

        _ = Promise6 { seal in
            seal.fulfill(Error.dummy)
        }

        _ = Promise6<Error>.pending()

        _ = Promise6.value(Error.dummy)

        _ = Promise6().map { Error.dummy }
    }

#if swift(>=3.1)
    func testCanMakeVoidPromise() {
        _ = Promise6()
        _ = Guarantee6()
    }
#endif

    enum Error: Swift.Error {
        case dummy
    }

    func testThrowInInitializer() {
        let p = Promise6<Void> { _ in
            throw Error.dummy
        }
        XCTAssertTrue(p.isRejected)
        guard let err = p.error, case Error.dummy = err else { return XCTFail() }
    }

    func testThrowInFirstly() {
        let ex = expectation(description: "")

        firstly { () -> Promise6<Int> in
            throw Error.dummy
        }.catch {
            XCTAssertEqual($0 as? Error, Error.dummy)
            ex.fulfill()
        }

        wait(for: [ex], timeout: 10)
    }

    func testWait() throws {
        let p = after(.milliseconds(100)).then(on: nil){ Promise6.value(1) }
        XCTAssertEqual(try p.wait(), 1)

        do {
            let p = after(.milliseconds(100)).map(on: nil){ throw Error.dummy }
            try p.wait()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? Error, Error.dummy)
        }
    }

    func testPipeForResolved() {
        let ex = expectation(description: "")
        Promise6.value(1).done {
            XCTAssertEqual(1, $0)
            ex.fulfill()
        }.silenceWarning()
        wait(for: [ex], timeout: 10)
    }
}
