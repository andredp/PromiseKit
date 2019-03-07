import PromiseKit6
import XCTest

class HangTests: XCTestCase {
    func test() {
        let ex = expectation(description: "block executed")
        do {
            let value = try hang6(after6(seconds: 0.02).then { _ -> Promise6<Int> in
                ex.fulfill()
                return .value(1)
            })
            XCTAssertEqual(value, 1)
        } catch {
            XCTFail("Unexpected error")
        }
        waitForExpectations(timeout: 0)
    }

    enum Error: Swift.Error {
        case test
    }

    func testError() {
        var value = 0
        do {
            _ = try hang6(after6(seconds: 0.02).done {
                value = 1
                throw Error.test
            })
            XCTAssertEqual(value, 1)
        } catch Error.test {
            return
        } catch {
            XCTFail("Unexpected error (expected Error.test)")
        }
        XCTFail("Expected error but no error was thrown")
    }
}
