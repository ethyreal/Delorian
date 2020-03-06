//
//  Bundle+Querying.swift
//  Delorian
//
//  Created by George Webster on 3/6/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import Foundation

extension Bundle {
    func url(forJsonFile fileName: String) -> URL? {
        url(forResource: fileName, withExtension: "json")
    }
}

enum BundleError: Error {
    case urlCreation
}

public func urlForJsonFile(_ fileName: String, in bundle: Bundle) -> Result<URL, Error> {
    switch bundle.url(forJsonFile: fileName) {
    case .some(let url):
        return .success(url)
    case .none:
        return .failure(BundleError.urlCreation)
    }
}
