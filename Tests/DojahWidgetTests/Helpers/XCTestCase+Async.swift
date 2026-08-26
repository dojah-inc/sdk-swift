import XCTest

extension XCTestCase {
    func waitForMainQueue(timeout: TimeInterval = 0.5) {
        let expectation = expectation(description: "main-queue")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: timeout)
    }

    func waitForRunAfter(delay: TimeInterval = 0.55, timeout: TimeInterval = 1.5) {
        let expectation = expectation(description: "run-after")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
}
