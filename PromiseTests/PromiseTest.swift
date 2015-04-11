//
//  PromiseTest.swift
//  promise-swift
//
//  Created by Damien Le Berrigaud on 4/11/15.
//
//

import XCTest
import Promise

class PromiseTest: XCTestCase {
    var promise = Promise<String>()
    var successes: [String] = []
    var errors: [String] = []

    override func setUp() {
        promise = Promise<String>()
        successes = []
        errors = []
    }

    func testResolve() {
        promise.onSuccess { value in
            self.successes.append("exec 1 with \(value)")
        }

        promise.onError { error in
            self.errors.append("exec 1 with \(error.message)")
        }

        XCTAssertEqual(0, successes.count)
        XCTAssertEqual(0, errors.count)

        promise.onSuccess { value in
            self.successes.append("exec 2 with \(value)")
        }

        XCTAssertEqual(0, successes.count)
        XCTAssertEqual(0, errors.count)

        promise.resolve("Hello")

        XCTAssertEqual(2, successes.count)
        if (successes.count == 2) {
            XCTAssertEqual("exec 1 with Hello", successes[0])
            XCTAssertEqual("exec 2 with Hello", successes[1])
        }
        XCTAssertEqual(0, errors.count)

        promise.onSuccess { value in
            self.successes.append("exec 3 with \(value)")
        }

        XCTAssertEqual(3, successes.count)
        if (successes.count == 3) {
            XCTAssertEqual("exec 1 with Hello", successes[0])
            XCTAssertEqual("exec 2 with Hello", successes[1])
            XCTAssertEqual("exec 3 with Hello", successes[2])
        }
        XCTAssertEqual(0, errors.count)
    }

    func testResolve_InThreadedContext() {
        var waitOnThreads = expectationWithDescription("Waiting on threads")

        promise.onSuccess { value in
            self.successes.append("exec 1 with \(value)")
        }

        doInBackground {
            self.promise.onSuccess { value in
                self.successes.append("exec 2 with \(value)")
            }

            self.promise.onSuccess { value in
                self.successes.append("exec 3 with \(value)")
            }

            waitOnThreads.fulfill()
        }

        self.promise.resolve("Hello")

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertEqual(3, successes.count)
        if (successes.count == 3) {
            XCTAssertEqual("exec 1 with Hello", successes[0])
            XCTAssertEqual("exec 2 with Hello", successes[1])
            XCTAssertEqual("exec 3 with Hello", successes[2])
        }
    }

    func testReject() {
        promise.onError { error in
            self.errors.append("exec 1 with \(error.message)")
        }

        promise.onSuccess { value in
            self.successes.append("exec 1 with \(value)")
        }

        XCTAssertEqual(0, successes.count)
        XCTAssertEqual(0, errors.count)

        promise.onError { error in
            self.errors.append("exec 2 with \(error.message)")
        }

        XCTAssertEqual(0, successes.count)
        XCTAssertEqual(0, errors.count)

        promise.reject(PromiseError(message: "Oops"))

        XCTAssertEqual(0, successes.count)
        XCTAssertEqual(2, errors.count)
        if (errors.count == 2) {
            XCTAssertEqual("exec 1 with Oops", errors[0])
            XCTAssertEqual("exec 2 with Oops", errors[1])
        }

        promise.onError { error in
            self.errors.append("exec 3 with \(error.message)")
        }

        XCTAssertEqual(0, successes.count)
        XCTAssertEqual(3, errors.count)
        if (errors.count == 3) {
            XCTAssertEqual("exec 1 with Oops", errors[0])
            XCTAssertEqual("exec 2 with Oops", errors[1])
            XCTAssertEqual("exec 3 with Oops", errors[2])
        }
    }

    func testReject_InThreadedContext() {
        var waitOnThreads = expectationWithDescription("Waiting on threads")

        promise.onError { error in
            self.errors.append("exec 1 with \(error.message)")
        }

        doInBackground {
            self.promise.onError { error in
                self.errors.append("exec 2 with \(error.message)")
            }

            self.promise.onError { error in
                self.errors.append("exec 3 with \(error.message)")
            }

            waitOnThreads.fulfill()
        }

        self.promise.reject(PromiseError(message: "Oops"))

        waitForExpectationsWithTimeout(0.5, handler: nil)

        XCTAssertEqual(3, errors.count)
        if (errors.count == 3) {
            XCTAssertEqual("exec 1 with Oops", errors[0])
            XCTAssertEqual("exec 2 with Oops", errors[1])
            XCTAssertEqual("exec 3 with Oops", errors[2])
        }
    }

    private func doInBackground(f: () -> Void) {
        let bgQueue = dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.value), 0)
        dispatch_async(bgQueue, f)
    }
}
