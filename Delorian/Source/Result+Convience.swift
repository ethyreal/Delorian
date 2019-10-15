//
//  Result+Convience.swift
//  Delorian
//
//  Created by George Webster on 10/15/19.
//  Copyright © 2019 George Webster. All rights reserved.
//

import Foundation

extension Result {

    public var value:Success? {
        return try? get()
    }

    public var error:Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}


//MARK:- Debugging

public func trace<T, U>(_ a: Result<T, U>) -> Result<T, U> {
    print("Result: \(a)")
    return a
}

public func trace<T, U>(_ a: T) -> Result<T, U> {
    print("Value: \(a)")
    return .success(a)
}
