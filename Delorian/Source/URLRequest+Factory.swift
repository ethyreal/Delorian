//
//  URLRequest+Factory.swift
//  Delorian
//
//  Created by George Webster on 3/6/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import Foundation

extension URLRequest {
    
    public init(_ url: URL, action: Action<Data>, headers: RequestHeaders = [:], cookies: [HTTPCookie] = []) {
        self.init(url: url)
        self.add(headers: headers)
        self.add(cookies: cookies)
        self.httpMethod = action.method
        self.httpBody = action.body
    }
    
    public init(_  url: URL, formAction: Action<JsonDictionary>) {
        let action = formAction
            .map { $0.flatMap(formEncodedStringFromJson) }
            .map { $0?.data(using: .utf8) }
        self.init(url, action: action, headers: Headers.webBase)
    }

    
}
