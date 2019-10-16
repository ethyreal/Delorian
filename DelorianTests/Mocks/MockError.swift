//
//  MockError.swift
//  DelorianTests
//
//  Created by George Webster on 10/16/19.
//  Copyright © 2019 George Webster. All rights reserved.
//

import Foundation

struct MockError: Error, Equatable {

    let code: Int
    let domain: String
}

extension MockError {
    init() {
        self.init(code: 800, domain: "com.ethyreal.mockErrors")
    }
}
