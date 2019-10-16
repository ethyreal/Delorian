//
//  FutureTests.swift
//  DelorianTests
//
//  Created by George Webster on 10/15/19.
//  Copyright © 2019 George Webster. All rights reserved.
//

import XCTest
@testable import Delorian

class FutureTests: XCTestCase {
    let backgroundQueue = DispatchQueue.global(qos: .userInitiated)
}

extension FutureTests {

    func testAsync() {

        let exp = expectation(description: "async")

        let sut = Future<Int>(on: DispatchQueue.main) { callback in
            self.backgroundQueue.asyncAfter(deadline: .now() + 2) {
                callback(Result<Int, Error>.success(88))
            }
        }
        sut.onResult { (result) in
            XCTAssertNotNil(result.value)
            XCTAssert(result.value == 88)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 10)
    }

    func testAsync_multipleCallbacks() {

        let sut = Future<Int>(on: DispatchQueue.main) { callback in
            self.backgroundQueue.asyncAfter(deadline: .now() + 2) {
                callback(Result<Int, Error>.success(88))
            }
        }
        let exps = [expectation(description: "1st async"), expectation(description: "2nd async"), expectation(description: "3rd async")]
        exps.forEach { exp in
            sut.onResult { (result) in
                XCTAssertNotNil(result.value)
                XCTAssert(result.value == 88)
                exp.fulfill()
            }
        }
        wait(for: exps, timeout: 10)
    }


    func testAsync_failure() {

        let exp = expectation(description: "async")

        let underlyingError = MockError()
        let sut = Future<String>(on: DispatchQueue.main) { callback in
            self.backgroundQueue.asyncAfter(deadline: .now() + 2) {
                callback(Result<String, Error>.failure(underlyingError))
            }
        }
        sut.onResult { (result) in
            _ = result.map { _ in
                XCTFail("should have no value to map over")
            }
            _ = result.mapError { (error) -> Error in
                guard let err = error as? MockError else {
                    XCTFail("expected MockError")
                    return error
                }
                XCTAssert(err.code == underlyingError.code)
                return err
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 10)
    }


    func testFlatMap() {

        let exp = expectation(description: "async")

        _ = Future<String>(on: DispatchQueue.main) { completion in
            self.backgroundQueue.asyncAfter(deadline: .now() + 2) {
                completion(Result<String, Error>.success("back to the future!"))
            }
        }.flatMap { value in
            return Future<String>(on: DispatchQueue.main) { completion in
                completion(Result<String, Error>.success(value.uppercased()))
            }
        }.onResult { (result) in
            XCTAssertNotNil(result.value)
            XCTAssert(result.value == "BACK TO THE FUTURE!")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 10)

    }
}

extension FutureTests {

    func testInit_withValue() {
        let expected = "Make like a tree..."
        var actual:String? = nil
        let sut = Future(value: expected)
        sut.onResult { (result) in
            actual = result.value
        }
        XCTAssertNotNil(actual, "callback should have been called immediatly to set this")
        XCTAssert(actual == expected)
    }

    func testInit_withError() {
        let expected = MockError()
        var actual:Error? = nil
        let sut = Future<Bool>(error: expected)
        sut.onResult { (result) in
            actual = result.error
        }
        XCTAssertNotNil(actual, "callback should have been called immediatly to set this")
        XCTAssert((actual as? MockError) == expected)
    }

}
