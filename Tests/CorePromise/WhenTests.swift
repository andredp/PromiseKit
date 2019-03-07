import PromiseKit6
import Dispatch
import XCTest

class WhenTests: XCTestCase {

    func testEmpty() {
        let e1 = expectation(description: "")
        let promises: [Promise6<Void>] = []
        when6(fulfilled: promises).done { _ in
            e1.fulfill()
        }.silenceWarning()

        let e2 = expectation(description: "")
        when6(resolved: promises).done { _ in
            e2.fulfill()
        }.silenceWarning()

        wait(for: [e1, e2], timeout: 1)
    }

    func testInt() {
        let e1 = expectation(description: "")
        let p1 = Promise6.value(1)
        let p2 = Promise6.value(2)
        let p3 = Promise6.value(3)
        let p4 = Promise6.value(4)

        when6(fulfilled: [p1, p2, p3, p4]).done { x in
            XCTAssertEqual(x[0], 1)
            XCTAssertEqual(x[1], 2)
            XCTAssertEqual(x[2], 3)
            XCTAssertEqual(x[3], 4)
            XCTAssertEqual(x.count, 4)
            e1.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDoubleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise6.value(1)
        let p2 = Promise6.value("abc")
        when6(fulfilled: p1, p2).done{ x, y in
            XCTAssertEqual(x, 1)
            XCTAssertEqual(y, "abc")
            e1.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTripleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise6.value(1)
        let p2 = Promise6.value("abc")
        let p3 = Promise6.value(     1.0)
        when6(fulfilled: p1, p2, p3).done { u, v, w in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            e1.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQuadrupleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise6.value(1)
        let p2 = Promise6.value("abc")
        let p3 = Promise6.value(1.0)
        let p4 = Promise6.value(true)
        when6(fulfilled: p1, p2, p3, p4).done { u, v, w, x in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            XCTAssertEqual(true, x)
            e1.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQuintupleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise6.value(1)
        let p2 = Promise6.value("abc")
        let p3 = Promise6.value(1.0)
        let p4 = Promise6.value(true)
        let p5 = Promise6.value("a" as Character)
        when6(fulfilled: p1, p2, p3, p4, p5).done { u, v, w, x, y in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            XCTAssertEqual(true, x)
            XCTAssertEqual("a" as Character, y)
            e1.fulfill()
        }.silenceWarning()
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testVoid() {
        let e1 = expectation(description: "")
        let p1 = Promise6.value(1).done { _ in }
        let p2 = Promise6.value(2).done { _ in }
        let p3 = Promise6.value(3).done { _ in }
        let p4 = Promise6.value(4).done { _ in }

        when6(fulfilled: p1, p2, p3, p4).done(e1.fulfill).silenceWarning()

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRejected() {
        enum Error: Swift.Error { case dummy }

        let e1 = expectation(description: "")
        let p1 = after6(.milliseconds(100)).map{ true }
        let p2: Promise6<Bool> = after6(.milliseconds(200)).map{ throw Error.dummy }
        let p3 = Promise6.value(false)
            
        when6(fulfilled: p1, p2, p3).catch { _ in
            e1.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgress() {
        let ex = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after6(.milliseconds(10))
        let p2 = after6(.milliseconds(20))
        let p3 = after6(.milliseconds(30))
        let p4 = after6(.milliseconds(40))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        when6(fulfilled: p1, p2, p3, p4).done { _ in
            XCTAssertEqual(progress.completedUnitCount, 1)
            ex.fulfill()
        }.silenceWarning()

        progress.resignCurrent()
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgressDoesNotExceed100Percent() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after6(.milliseconds(10))
        let p2 = after6(.milliseconds(20)).done { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = after6(.milliseconds(30))
        let p4 = after6(.milliseconds(40))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        let promise = when6(fulfilled: p1, p2, p3, p4)

        progress.resignCurrent()

        promise.catch { _ in
            ex2.fulfill()
        }

        var x = 0
        func finally() {
            x += 1
            if x == 4 {
                XCTAssertLessThanOrEqual(1, progress.fractionCompleted)
                XCTAssertEqual(progress.completedUnitCount, 1)
                ex1.fulfill()
            }
        }

        let q = DispatchQueue.main
        p1.done(on: q, finally)
        p2.ensure(on: q, finally).silenceWarning()
        p3.done(on: q, finally)
        p4.done(on: q, finally)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFire() {
        enum Error: Swift.Error {
            case test
        }

        let ex = expectation(description: "")
        let p1 = Promise6<Void>(error: Error.test)
        let p2 = after6(.milliseconds(100))
        when6(fulfilled: p1, p2).done{ _ in XCTFail() }.catch { error in
            XCTAssertTrue(error as? Error == Error.test)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFireForStragglers() {
        enum Error: Swift.Error {
            case test
            case straggler
        }

        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        let ex3 = expectation(description: "")

        let p1 = Promise6<Void>(error: Error.test)
        let p2 = after6(.milliseconds(100)).done { throw Error.straggler }
        let p3 = after6(.milliseconds(200)).done { throw Error.straggler }

        when6(fulfilled: p1, p2, p3).catch { error -> Void in
            XCTAssertTrue(Error.test == error as? Error)
            ex1.fulfill()
        }

        p2.ensure { after6(.milliseconds(100)).done(ex2.fulfill) }.silenceWarning()
        p3.ensure { after6(.milliseconds(100)).done(ex3.fulfill) }.silenceWarning()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAllSealedRejectedFirstOneRejects() {
        enum Error: Swift.Error {
            case test1
            case test2
            case test3
        }

        let ex = expectation(description: "")
        let p1 = Promise6<Void>(error: Error.test1)
        let p2 = Promise6<Void>(error: Error.test2)
        let p3 = Promise6<Void>(error: Error.test3)

        when6(fulfilled: p1, p2, p3).catch { error in
            XCTAssertTrue(error as? Error == Error.test1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testGuaranteeWhen() {
        let ex1 = expectation(description: "")
        when6(Guarantee6(), Guarantee6()).done {
            ex1.fulfill()
        }

        let ex2 = expectation(description: "")
        when6(guarantees: [Guarantee6(), Guarantee6()]).done {
            ex2.fulfill()
        }

        wait(for: [ex1, ex2], timeout: 10)
    }
}
