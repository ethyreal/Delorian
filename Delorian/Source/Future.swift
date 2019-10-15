//
//  Future.swift
//  Delorian
//
//  Created by George Webster on 10/15/19.
//  Copyright © 2019 George Webster. All rights reserved.
//

import Foundation

public final class Future<Value> {

    private var callbacks: [(Result<Value, Error>) -> ()] = []

    private var cached: Result<Value, Error>?

    private let notifyQueue: DispatchQueue

    private let lockQueue = DispatchQueue(label: "future.internal.locking.queue", qos: .userInitiated, attributes: .concurrent)

    /// Creates a container of a value in the `Future`
    /// - Parameter notifyQueue: a `DispatchQueue` the caller wishes to be notified on (eg. DispatchQueue.main).
    /// - Parameter work: Closure representing the work to proform.  Takes a callback to return the result of the work
    public init(on notifyQueue: DispatchQueue, work: @escaping ( @escaping (Result<Value, Error>) -> Void ) -> Void) {
        self.notifyQueue = notifyQueue
        work(self._setValue)
    }

    public init(on notifyQueue: DispatchQueue = DispatchQueue.main, value:Value) {
        self.notifyQueue = notifyQueue
        self._setValue(.success(value))
    }

    public init(on notifyQueue: DispatchQueue = DispatchQueue.main, error:Error) {
        self.notifyQueue = notifyQueue
        self._setValue(.failure(error))
    }


    /// Adds a callback which will be called when the future is realized.  If the future is now, then the callback is called immediatly
    /// - Parameter callback: Callback with a single Result of the of the work requested
    public func onResult(_ callback: @escaping (Result<Value, Error>) -> ()) {
        lockQueue.sync {
            if let value = cached {
                callback(value)
            } else {
                self._addCallback(callback)
            }
        }
    }


    /// When the current `Future<Value>` is realized run the provided transform, which provides a new Future
    /// This is sometimes referred as `then` or `chain` in some promise implementaitons
    /// It is a way of chaining one future value/request into another
    /// - Parameter transform: A closure that will receive the value of this `Future` and return a new `Future`
    public func flatMap<NewValue>(_ transform: @escaping (Value) -> Future<NewValue>) -> Future<NewValue> {
        return Future<NewValue>(on: notifyQueue) { callback in
            self.onResult { (result) in
                switch result {
                case .success(let value):
                    transform(value).onResult(callback)
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }
    }

    private func _setValue(_ value: Result<Value, Error>) {
        lockQueue.async(flags: .barrier) {
            assert(self.cached == nil, "set value should only be called once!!")
            guard self.cached == nil else { return }
            self.cached = value
            self.callbacks.forEach { callback in
                self.notifyQueue.async {
                    callback(value)
                }
            }
            self.callbacks = []
        }
    }

    private func _addCallback(_ callback: @escaping (Result<Value, Error>) -> ()) {
        lockQueue.async(flags: .barrier) {
            self.callbacks.append(callback)
        }
    }
}
