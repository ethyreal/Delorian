//
//  MockDataTransport.swift
//  DelorianTests
//
//  Created by George Webster on 3/4/20.
//  Copyright © 2020 George Webster. All rights reserved.
//

import Foundation
@testable import Delorian

class MockDataTransport: DataTransport {
    
    var delay: TimeInterval = 0

    var result: Result<(Data, HTTPResponseMeta), Error> = .failure(DataTransportError.invalidUrl)
    
    var onComplete: (Result<(Data, HTTPResponseMeta), Error>) -> Void = { _ in }

    func loadRequest(_ request: URLRequest, completion: @escaping (Result<(Data, HTTPResponseMeta), Error>) -> Void) -> Cancellable {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            completion(self.result)
            self.onComplete(self.result)
        }
        return MockCancellable()
    }
    
}

class MockCancellable: Cancellable {
    
    func cancel() {
    }
}
