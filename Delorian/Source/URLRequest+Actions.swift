//
//  URLRequest+Actions.swift
//  Delorian
//
//  Created by George Webster on 3/6/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import Foundation

extension URLRequest {

    /// Representation of a remote action, HTTP method + payload
    ///
    /// - get: GET request
    /// - post: Create with optional Payload ( request body )
    /// - put: Edit/Create with optional Payload ( request body )
    /// - delete: Delete with optional Payload
    ///
    public enum Action<Body> {
        case get
        case post(Body?)
        case put(Body?)
        case delete(Body?)
    }
}

//MARK:- Accessors

extension URLRequest.Action {
    
    /// HTTP method
    public var method: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .delete: return "DELETE"
        }
    }
    
    /// Associated `Body` value of the action.  Usually represensts a URLRequest's `httpBody` value
    public var body: Body? {
        switch self {
        case let .post(data):
            return data
        case let .put(data):
            return data
        case let .delete(data):
            return data
        default:
            return nil
        }
    }

}

//MARK:- Transforms

extension URLRequest.Action {

    /// Transforms an actions paylaod
    ///
    /// - Parameter f: A closure that takes the existing associated `body` type of this instance.
    /// - Returns: A `Action` instance with the result of evaluating the tranform on the action's body.
    public func map<B>(_ f: (Body?) -> B?) -> URLRequest.Action<B> {
        switch self {
        case .get:
            return .get
        case .post(let body):
            return .post(f(body))
        case .put(let body):
            return .put(f(body))
        case .delete(let body):
            return .delete(f(body))
        }
    }
}
