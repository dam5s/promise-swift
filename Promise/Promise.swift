//
//  Promise.swift
//  promise-swift
//
//  Created by Damien Le Berrigaud on 4/11/15.
//
//

import Foundation

public class Promise<T> {
    private let lockQueue = dispatch_queue_create("io.damo.Promise.LockQueue", nil);

    private var successCallbacks: [(T) -> Void] = []
    private var value: T?

    private var errorCallbacks: [(PromiseError) -> Void] = []
    private var error: PromiseError?

    public init() {
    }

    public func onSuccess(callback: (T) -> Void) {
        synchronized {
            self.value.map(callback)
            self.successCallbacks.append(callback)
        }
    }

    public func resolve(value: T) {
        synchronized {
            self.verifyNotResolvedOrRejected()

            self.value = value
            for callback in self.successCallbacks {
                callback(value)
            }
        }
    }

    public func onError(callback: (PromiseError) -> Void) {
        synchronized {
            self.error.map(callback)
            self.errorCallbacks.append(callback)
        }
    }

    public func reject(error: PromiseError) {
        synchronized {
            self.verifyNotResolvedOrRejected()

            self.error = error
            for callback in self.errorCallbacks {
                callback(error)
            }
        }
    }

    private func verifyNotResolvedOrRejected() {
        if (value != nil) {
            assertionFailure("Promise has already been resolved with \(value!).")
        }

        if (error != nil) {
            assertionFailure("Promise has already been rejected with \(error!.message).")
        }
    }

    private func synchronized(f: () -> Void) {
        dispatch_sync(lockQueue, f)
    }
}

public class PromiseError {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}
