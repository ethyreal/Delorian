//
//  JsonConversion.swift
//  Delorian
//
//  Created by George Webster on 3/6/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import Foundation

public typealias JsonDictionary = [String: Any]

public func dataFromJson(_ json: JsonDictionary) -> Result<Data, Error> {
    json.toData().flatMap { .success($0) } ?? .failure(JsonError.dictionaryConversion)
}

public func dataFromJsonFile(_ fileName: String, in bundle: Bundle) -> Result<Data, Error> {
    return urlForJsonFile(fileName, in: bundle)
        .flatMap(trace)
        .flatMap(dataForURL)
}

public func dataForURL(_ url: URL) -> Result<Data, Error> {
    Result { try Data(contentsOf: url) }
}

public func dataFromJsonString(_ json: String?) -> Result<Data, Error> {
    json.flatMap { $0.data(using: .utf8) }
        .flatMap { .success($0) }
        ?? .failure(JsonError.stringSerialization)
}

public func jsonDictionaryFromData(_ data: Data) -> Result<JsonDictionary, Error> {
    return data.toJsonDictionary()
}

public func jsonDictionaryFromJsonFile(_ fileName: String, in bundle: Bundle = Bundle.main) -> Result<JsonDictionary, Error> {
    return dataFromJsonFile(fileName, in: bundle)
        .flatMap(jsonDictionaryFromData)
}

public func formEncodedStringFromJson(_ json: JsonDictionary) -> String? {
    return json.toFormEncodedString()
}

public func prettifyJsonData(_ data: Data) -> Result<Data, Error> {
    jsonDictionaryFromData(data).flatMap(dataFromJson)
}

extension Dictionary where Key == String {
    
    public func toData(options: JSONSerialization.WritingOptions = [.prettyPrinted]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: options)
    }
    
    public func toFormEncodedString() -> String? {
        return self.map { $0.addingFormEncoding() + "=" + String(describing: $1).addingFormEncoding() }
            .joined(separator: "&")
    }
}

enum JsonError: Error {
    case dictionaryConversion
    case stringSerialization
}

extension Data {
    
    public func toJsonDictionary(options: JSONSerialization.ReadingOptions = .mutableContainers) -> Result<JsonDictionary, Error> {
        return Result {
            let obj = try JSONSerialization.jsonObject(with: self, options: options)
            guard let json = obj as? JsonDictionary else { throw JsonError.dictionaryConversion }
            return json
        }
    }
}
