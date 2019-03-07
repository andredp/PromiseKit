import PromiseKit6
import XCTest

class PMKErrorTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertNotNil(PMKError6.invalidCallingConvention.errorDescription)
        XCTAssertNotNil(PMKError6.returnedSelf.errorDescription)
        XCTAssertNotNil(PMKError6.badInput.errorDescription)
        XCTAssertNotNil(PMKError6.cancelled.errorDescription)
        XCTAssertNotNil(PMKError6.compactMap(1, Int.self).errorDescription)
        XCTAssertNotNil(PMKError6.emptySequence.errorDescription)
    }

    func testCustomDebugStringConvertible() {
        XCTAssertFalse(PMKError6.invalidCallingConvention.debugDescription.isEmpty)
        XCTAssertFalse(PMKError6.returnedSelf.debugDescription.isEmpty)
        XCTAssertNotNil(PMKError6.badInput.debugDescription.isEmpty)
        XCTAssertFalse(PMKError6.cancelled.debugDescription.isEmpty)
        XCTAssertFalse(PMKError6.compactMap(1, Int.self).debugDescription.isEmpty)
        XCTAssertFalse(PMKError6.emptySequence.debugDescription.isEmpty)
    }
}
