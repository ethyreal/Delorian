//
//  URLRequest+Headers.swift
//  Delorian
//
//  Created by George Webster on 3/6/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import Foundation

public typealias RequestHeaders = [String: String]

extension URLRequest {
    
    public enum Headers {
        
        public static let jsonBase: RequestHeaders = [
            "Accept": "application/json",
            "Accept-Encoding": "gzip",
            "Content-Type": "application/json"
        ]
        
        public static let webBase: RequestHeaders = [
            "Accept-Encoding": "gzip",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
    }
}

extension URLRequest {
    
    /**
     Appends an array of cookies to any existing cookies, then adds them as header items to the request.
     
     - parameter cookies: Array of NSHTTPCookie objects
     */
    public mutating func add(cookies:[HTTPCookie]) {
        
        let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
        self.add(headers: cookieHeaders)
    }
    
    /**
     Appends a collection of key/value pairs as headers in the request.
     
     - parameter headers: Dictionary of headers, these will override any existing one's with the same name
     */
    public mutating func add(headers: RequestHeaders) {
        
        guard var currentHeaders = allHTTPHeaderFields else {
            allHTTPHeaderFields = headers
            return
        }
        headers.forEach { currentHeaders[$0] = $1 }
        allHTTPHeaderFields = currentHeaders
    }
}
