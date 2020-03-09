//
//  String+Encoding.swift
//  Delorian
//
//  Created by George Webster on 3/9/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import Foundation

extension String {
    public func addingFormEncoding() -> String {
        var allowed = CharacterSet.alphanumerics
        let unreserved = "*-._"
        allowed.insert(charactersIn: unreserved)
        allowed.insert(charactersIn: " ") // add space to + replace
        return addingPercentEncoding(withAllowedCharacters: allowed)?
            .replacingOccurrences(of: " ", with: "+")
            ?? ""
    }
}
