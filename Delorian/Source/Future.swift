//
//  Future.swift
//  Delorian
//
//  Created by George Webster on 10/15/19.
//  Copyright © 2019 George Webster. All rights reserved.
//

import Foundation

/// Future is a type and represents a value that may exist later
/// Essentially it's a wrapper for an asynchronous task and a callback
/// After the task is done the `Result` of it is sent to any subscribers ( callbacks )
/// Most implementations have `Promise` type that produces a `Future` or populates it with a result.
/// Currently our `Promise` is simplified to a closure that takes a closure as a parameter.
/// It is 'fulfilled' or 'rejected' by passing a `success` or `failure` to its closure parameter.
public final class Future<Value> {
    /// A Future's computation, It is 'fulfilled' or 'rejected' by passing a `success` or `failure` to its closure parameter.
    public typealias Promise<Value> = (@escaping (Result<Value, Error>) -> Void) -> Void
    private var successCallbacks: [(Value) -> ()] = []
    private var failureCallbacks: [(Error) -> ()] = []
    
    /// Promise State
    /// - pending: `nil`, no result set
    /// - fulfilled: `.success(Value)` is set
    /// - rejected: `.failure(Error)` is set
    private var cached: Result<Value, Error>?
    private let notifyQueue: DispatchQueue
    private let lockQueue = DispatchQueue(label: "future.internal.locking.queue", qos: .userInitiated, attributes: .concurrent)
    /// Creates a container of a value in the `Future`
    /// - Parameter notifyQueue: a `DispatchQueue` the caller wishes to be notified on (eg. DispatchQueue.main).
    /// - Parameter promise: `Promise` representing the work to perform. It is 'fulfilled' or 'rejected' by passing a `success` or `failure` to its completion block.
    public init(on notifyQueue: DispatchQueue = .main, promise: Promise<Value>) {
        self.notifyQueue = notifyQueue
        promise() { result in
            self.setValue(result)
        }
    }
    
    /// Creates a Future with a success result value
    /// - Parameter notifyQueue: a `DispatchQueue` the caller wishes to be notified on (eg. DispatchQueue.main).
    /// - Parameter value: A value to wrap in a `Result.success`.
    public init(on notifyQueue: DispatchQueue = DispatchQueue.main, value:Value) {
        self.notifyQueue = notifyQueue
        self.setValue(.success(value))
    }
    
    /// Creates a Future with a failing result value
    /// - Parameter notifyQueue: a `DispatchQueue` the caller wishes to be notified on (eg. DispatchQueue.main).
    /// - Parameter value: An `error` to wrap in a `Result.failure`.
    public init(on notifyQueue: DispatchQueue = DispatchQueue.main, error:Error) {
        self.notifyQueue = notifyQueue
        self.setValue(.failure(error))
    }
    
    /// Adds a callback which will be called when the future is realized. If the future is now, then the callback is called immediately
    /// - Parameter callback: Callback with a single Result of the of the work requested
    /// - Returns: same `Future` with the `callback` applied
    @discardableResult
    public func onComplete(_ callback: @escaping (Result<Value, Error>) -> ()) -> Future<Value> {
        lockQueue.sync {
            guard let result = cached else {
                addSuccessCallback { callback(.success($0)) }
                addFailureCallback { callback(.failure($0)) }
                return self
            }
            callback(result)
            return self
        }
    }
    
    /// Adds a callback that will be called if the future result succeeds. If we already have a success the callback is called immediately.
    /// - Parameter callback: Closure that accepts the expected value
    /// - Returns: same `Future` with the `callback` applied
    @discardableResult
    public func onSuccess(_ callback: @escaping (Value) -> Void) -> Future<Value> {
        lockQueue.sync {
            guard let result = cached else {
                self.addSuccessCallback(callback)
                return self
            }
            if case let .success(value) = result {
                callback(value)
            }
            return self
        }
    }
    
    /// Adds a callback that will be called if the future result fails. If we already have a failure the callback is called immediately.
    /// - Parameter callback: Closure that accepts an error
    /// - Returns: same `Future` with the `callback` applied
    @discardableResult
    public func onFailure(_ callback: @escaping (Error) -> Void) -> Future<Value> {
        lockQueue.sync {
            guard let result = cached else {
                self.addFailureCallback(callback)
                return self
            }
            if case let .failure(error) = result {
                callback(error)
            }
            return self
        }
    }
    
    /// When the current `Future<Value>` is realized, run the provided transform, which provides a new Future
    /// This is sometimes referred as `then` or `chain` in some promise implementations
    /// It is a way of chaining one future value/request into another
    /// - Parameter transform: A closure that will receive the value of this `Future` and return a new `NewValue`
    /// - Returns: new `Future` whose `NewValue` is computed after the current one
    public func map<NewValue>(_ transform: @escaping (Value) throws -> NewValue) -> Future<NewValue> {
        Future<NewValue>(on: notifyQueue) { completion in
            self.onSuccess { (value) in
                let result = Result {
                    try transform(value)
                }
                completion(result)
            }
        }
    }
    
    /// When the current `Future<Value>` is realized, run the provided transform, which provides a new Future
    /// This is sometimes referred as `then` or `chain` in some promise implementations
    /// It is a way of chaining one future value/request into another
    /// - Parameter transform: A closure that will receive the value of this `Future` and return a new `Future`
    /// - Returns: new `Future` whose `NewValue` is computed after the current one
    public func flatMap<NewValue>(_ transform: @escaping (Value) -> Future<NewValue>) -> Future<NewValue> {
        Future<NewValue>(on: notifyQueue) { completion in
            self.onComplete { (result) in
                switch result {
                case .success(let value):
                    transform(value).onComplete { (result) in
                        completion(result)
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// If the current `Future<Value>` fails, run the provided transform to attempt to recover.
    /// This is sometimes referred as `recover` in some promise implementations
    /// It is a way of chaining one future failure into a new `Future<Value>`
    /// - Parameter transform: A closure that will receive the value of this `Future` and return a new `Future`
    public func orElse(_ transform: @escaping () -> Future<Value>) -> Future<Value> {
        Future(on: notifyQueue) { completion in
            self.onComplete { (result) in
                switch result {
                case .success:
                    completion(result)
                case .failure:
                    transform().onComplete { (result) in
                        completion(result)
                    }
                }
            }
        }
    }
}

private extension Future {
    
    func setValue(_ result: Result<Value, Error>) {
        lockQueue.async(flags: .barrier) {
            assert(self.cached == nil, "setValue should only be called once!!")
            guard self.cached == nil else { return }
            self.cached = result
            switch result {
            case .success(let value):
                self.successCallbacks.forEach { callback in
                    self.notifyQueue.async {
                        callback(value)
                    }
                }
            case .failure(let error):
                self.failureCallbacks.forEach { callback in
                    self.notifyQueue.async {
                        callback(error)
                    }
                }
            }
            self.successCallbacks = []
            self.failureCallbacks = []
        }
    }
    
    func addSuccessCallback(_ callback: @escaping (Value) -> ()) {
        lockQueue.async(flags: .barrier) {
            self.successCallbacks.append(callback)
        }
    }
    
    func addFailureCallback(_ callback: @escaping (Error) -> ()) {
        lockQueue.async(flags: .barrier) {
            self.failureCallbacks.append(callback)
        }
    }
}
