//
//  URLRequestFactoryTests.swift
//  DelorianTests
//
//  Created by George Webster on 3/6/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import XCTest
@testable import Delorian

class URLRequestFactoryTests: XCTestCase {

    let url = URL(string: "http://www.ethyreal.com")!

    func testRequest_hasCorrectMethodGET() {

        let sut = URLRequest(url, action: .get)
        XCTAssertEqual(sut.httpMethod, "GET")
    }

    func testRequest_hasCorrectMethodDELETE() {

        let sut = URLRequest(url, action: .delete(nil))
        XCTAssertEqual(sut.httpMethod, "DELETE")
    }

    func testRequest_hasCorrectMethodPUT() {
        let sut = URLRequest(url, action: .put(nil))
        XCTAssertEqual(sut.httpMethod, "PUT")
    }

    func testRequest_hasCorrectMethodPOST() {

        let sut = URLRequest(url, action: .post(nil))
        XCTAssertEqual(sut.httpMethod, "POST")
    }
}
