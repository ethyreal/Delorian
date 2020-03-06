//
//  JsonConversionTests.swift
//  DelorianTests
//
//  Created by George Webster on 3/6/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import XCTest
@testable import Delorian

class JsonConversionTests: XCTestCase {
}


//MARK:- dataFromJsonFile

extension JsonConversionTests {
    
    func testDataFromJsonFile_successForValidFile() {
        ["invalid",
         "movies"].forEach {
            let sut = dataFromJsonFile($0, in: Bundle(for: JsonConversionTests.self))
            XCTAssertNotNil(sut.value)
        }
    }
    
    func testDataFromJsonFile_failsForMissingFile() {
        let sut = dataFromJsonFile("some_busted_file", in: Bundle(for: JsonConversionTests.self))
        XCTAssertNil(sut.value)
    }
}


//MARK:- jsonDictionaryFromJsonFile

extension JsonConversionTests {

    func testJsonDictionaryFromJsonFile_successForValidJson() {
        ["movies"].forEach {
                let sut = jsonDictionaryFromJsonFile($0, in: Bundle(for: JsonConversionTests.self))
                XCTAssertNotNil(sut.value)
        }
    }
    
    func testJsonDictionaryFromJsonFile_failsForInvalidJson() {
        let sut = jsonDictionaryFromJsonFile("invalid", in: Bundle(for: JsonConversionTests.self))
        XCTAssertNil(sut.value)
    }
}
