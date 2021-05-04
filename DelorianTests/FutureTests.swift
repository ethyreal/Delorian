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
        let expSuccess = expectation(description: "async success")
        let expComplete = expectation(description: "async complete")
        let success = true
        let future = Future<Int>(on: .main) { promiseComplete in
            // calculate how fast you need to travel
            self.backgroundQueue.async {
                if success { // fulfill the promise
                    promiseComplete(.success(88))
                } else { // reject the promise
                    promiseComplete(.failure(MockError()))
                }
            }
        }
        future.onSuccess { (value) in
            XCTAssert(value == 88, "Expected 88 Miles Per Hour")
            expSuccess.fulfill()
        }
        future.onFailure { (error) in
            XCTFail("promise rejected with error: \(error)")
        }
        future.onComplete { (result) in
            expComplete.fulfill()
        }
        wait(for: [expSuccess, expComplete], timeout: 10)
    }
    
    func testAsync_multipleCallbacks() {
        let sut = Future<Int>() { callback in
            self.backgroundQueue.async {
                callback(.success(88))
            }
        }
        let exps = [expectation(description: "1st async"), expectation(description: "2nd async"), expectation(description: "3rd async")]
        exps.forEach { exp in
            sut.onComplete { (result) in
                do {
                    let value = try result.get()
                    XCTAssert(value == 88)
                } catch {
                    XCTFail("promise rejected with error: \(error)")
                }
                exp.fulfill()
            }
        }
        wait(for: exps, timeout: 10)
    }
    
    func testAsync_failure() {
        let exp = expectation(description: "async")
        let underlyingError = MockError()
        let sut = Future<String>(on: DispatchQueue.main) { callback in
            callback(.failure(underlyingError))
        }
        sut.onComplete { (result) in
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
    
    func testMap_success() {
        let exp = expectation(description: "async")
        _ = Future<String>() { completion in
            completion(.success("back to the future!"))
        }.map { value in
            value.uppercased()
        }.onSuccess { (value) in
            XCTAssert(value == "BACK TO THE FUTURE!")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func testFlatMap_success() {
        let exp = expectation(description: "async")
        _ = Future<String>() { completion in
            completion(.success("back to the future!"))
        }.flatMap { value in
            Future<String>() { completion in
                completion(.success(value.uppercased()))
            }
        }.onSuccess { (value) in
            XCTAssert(value == "BACK TO THE FUTURE!")
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
        sut.onComplete { (result) in
            actual = try? result.get()
        }
        XCTAssertNotNil(actual, "callback should have been called immediately to set this")
        XCTAssert(actual == expected)
    }
    
    func testInit_withError() {
        let expected = MockError()
        var actual:Error? = nil
        let sut = Future<Bool>(error: expected)
        sut.onComplete { (result) in
            if case let .failure(error) = result {
                actual = error
            }
        }
        XCTAssertNotNil(actual, "callback should have been called immediately to set this")
        XCTAssert((actual as? MockError) == expected)
    }
}
