//
//  StringEncodingTests.swift
//  DelorianTests
//
//  Created by George Webster on 3/9/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import XCTest
@testable import Delorian

class StringEncodingTests: XCTestCase {

    func testAddingFormEncoding() {
        ["make.like.a.tree@leave.com",
         "joe momma"]
            .forEach {
                let sut = $0.addingFormEncoding()
                XCTAssert(sut.count >= $0.count)
        }
        XCTAssert("check yo self".addingFormEncoding() == "check+yo+self")
    }
}
