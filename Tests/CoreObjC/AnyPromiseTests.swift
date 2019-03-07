import PromiseKit
import XCTest

class AnyPromiseTests: XCTestCase {
    func testFulfilledResult() {
        switch AnyPromise(Promise6.value(true)).result {
        case .fulfilled(let obj as Bool)? where obj:
            break
        default:
            XCTFail()
        }
    }

    func testRejectedResult() {
        switch AnyPromise(Promise6<Int>(error: PMKError.badInput)).result {
        case .rejected(let err)?:
            print(err)
            break
        default:
            XCTFail()
        }
    }

    func testPendingResult() {
        switch AnyPromise(Promise6<Int>.pending().promise).result {
        case nil:
            break
        default:
            XCTFail()
        }
    }

    func testCustomStringConvertible() {
        XCTAssertEqual("\(AnyPromise(Promise6<Int>.pending().promise))", "AnyPromise(…)")
        XCTAssertEqual("\(AnyPromise(Promise6.value(1)))", "AnyPromise(1)")
        XCTAssertEqual("\(AnyPromise(Promise6<Int?>.value(nil)))", "AnyPromise(nil)")
    }
}
