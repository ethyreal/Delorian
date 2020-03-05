//
//  DataTransferable.swift
//  Delorian
//
//  Created by George Webster on 12/17/19.
//  Copyright © 2019 George Webster. All rights reserved.
//

import Foundation

/// Network request basic interface
public protocol DataTransport {
    
    func loadRequest(_ request: URLRequest, completion: @escaping (Result<(Data, HTTPResponseMeta), Error>) -> Void) -> Cancellable
}

/// A representation of a cancellable process
public protocol Cancellable {
    func cancel()
}

extension URLSessionTask: Cancellable {}

extension URLSession: DataTransport {
    
    
    /// Load a URLRequest and send a nice Result to the completion
    ///  Basically converts `(Data?, URLResponse?, Error?) -> Void)` to `(Result<(Data, HTTPResponsable), Error>) -> Void)` to simplify parsing
    /// - Parameters:
    ///   - request: A `URLRequest` instance
    ///   - completion: A closure to continue parsing the response
    public func loadRequest(_ request: URLRequest, completion: @escaping (Result<(Data, HTTPResponseMeta), Error>) -> Void) -> Cancellable {
        let task = dataTask(with: request) { (data, response, error) in
            let result = validateErrors((data, response, error))
                .flatMap(validateHttpResponse)
                .flatMap(successHttpResponse)
                .map(normalizeResponseDTO)
            completion(result)
        }
        task.resume()
        return task
    }
}

/// A Description of the HTTPResponse meta data
public protocol HTTPResponseMeta {
    var statusCode: Int { get }
    var allHeaderFields: [AnyHashable : Any] { get }
}

extension HTTPURLResponse: HTTPResponseMeta {}



//MARK:- Response Parsing

func validateErrors(_ responseDTO: (Data?, URLResponse?, Error?)) -> Result<(Data?, URLResponse?), Error> {
    let (data, response, error) = responseDTO
    switch error {
    case .some(let systemError): return .failure(systemError)
    case .none: return .success((data, response))
    }
}

func validateHttpResponse(_ responseDTO: (Data?, URLResponse?)) -> Result<(Data?, HTTPURLResponse), Error> {
    let (data, response) = responseDTO
    guard let httpResponse = response as? HTTPURLResponse else {
        return .failure(DataTransportError.invalidUrl)
    }
    return .success((data, httpResponse))
}

func successHttpResponse(_ responseDTO: (Data?, HTTPURLResponse)) -> Result<(Data?, HTTPURLResponse), Error> {
    let (data, response) = responseDTO
    if case 200..<300 = response.statusCode {
        return .success((data, response))
    }
    return .failure(DataTransportError.failureResponse(response, body: data))
}

func normalizeResponseDTO(_ responseDTO: (Data?, HTTPURLResponse)) -> (Data, HTTPResponseMeta) {
    return (responseDTO.0 ?? Data(), responseDTO.1)
}

public enum DataTransportError: Error {
    case invalidUrl
    case failureResponse(HTTPResponseMeta, body: Data?)
}
