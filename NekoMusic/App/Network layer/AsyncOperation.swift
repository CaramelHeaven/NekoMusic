//
//  AsyncOperation.swift
//  NekoMusic
//
//  Created by Sergey Fominov on 09/05/2020.
//  Copyright © 2020 NekoMusic. All rights reserved.
//

import Foundation

/*
 Async with dependencies, AsyncOperation - base class for concurrency
 from SO -  https://gist.github.com/Sorix/57bc3295dc001434fe08acbb053ed2bc
 */
class AsyncOperation: Operation {
    /// State for this operation.
    @objc private enum OperationState: Int {
        case ready
        case executing
        case finished
    }

    /// Concurrent queue for synchronizing access to `state`.
    private let stateQueue = DispatchQueue(label: "async-concurrent-dispatch-queue", attributes: .concurrent)

    /// Private backing stored property for `state`.
    private var _state: OperationState = .ready

    /// The state of the operation
    @objc private dynamic var state: OperationState {
        get { return stateQueue.sync { _state } }
        set { stateQueue.async(flags: .barrier) { self._state = newValue } }
    }

    // MARK: - Various `Operation` properties

    open override var isReady: Bool { return self.state == .ready && super.isReady }
    public final override var isExecuting: Bool { return self.state == .executing }
    public final override var isFinished: Bool { return state == .finished }

    // KVN for dependent properties
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }

        return super.keyPathsForValuesAffectingValue(forKey: key)
    }

    // Start
    public final override func start() {
        if isCancelled {
            self.state = .finished
            return
        }

        self.state = .executing

        self.main()
    }

    // Allow us to cancel executing operation
    override func cancel() {
        self.state = .finished
    }

    /*
     Subclasses must implement this to perform their work and they must not call `super`.
     The default implementation of this function throws an exception.
     */
    open override func main() {
        fatalError("Subclasses mustn't implement `main`.")
    }

    /// Call this function to finish an operation that is currently executing
    func finish() {
        if !self.isFinished { self.state = .finished }
    }
}
