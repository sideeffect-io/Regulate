//
//  Throttler.swift
//  Debounce
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

import Foundation

public final class Throttler<Value>: @unchecked Sendable, ObservableObject, Regulator {
  struct StateMachine {
    enum State {
      case idle
      case throttlingWithNoValues
      case throttlingWithFirst(first: Value)
      case throttlingWithFirstAndLast(first: Value, last: Value)
    }

    var state: State = .idle

    mutating func newValue(_ value: Value) -> Bool {
      switch self.state {
        case .idle:
          self.state = .throttlingWithFirst(first: value)
          return true
        case .throttlingWithFirst(let first), .throttlingWithFirstAndLast(let first, _):
          self.state = .throttlingWithFirstAndLast(first: first, last: value)
          return false
        case .throttlingWithNoValues:
          self.state = .throttlingWithFirst(first: value)
          return false
      }
    }

    enum HasTickedOutput {
      case finishThrottling
      case continueThrottling(first: Value, last: Value)
    }

    mutating func hasTicked() -> HasTickedOutput {
      switch state {
        case .idle:
          fatalError("inconsistent state, a value was being debounced")
        case .throttlingWithFirst(let first):
          self.state = .throttlingWithNoValues
          return .continueThrottling(first: first, last: first)
        case .throttlingWithFirstAndLast(let first, let last):
          self.state = .throttlingWithNoValues
          return .continueThrottling(first: first, last: last)
        case .throttlingWithNoValues:
          self.state = .idle
          return .finishThrottling
      }
    }
  }

  public var output: (@Sendable (Value) async -> Void)?

  private let dueTime: DispatchTimeInterval
  private let latest: Bool
  private let lock: os_unfair_lock_t = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
  private var stateMachine = StateMachine()
  private var task: Task<Void, Never>?

  public init(
    dueTime: DispatchTimeInterval,
    latest: Bool = true,
    output: (@Sendable (Value) async -> Void)? = nil
  ) {
    self.lock.initialize(to: os_unfair_lock())
    self.dueTime = dueTime
    self.latest = latest
    self.output = output
  }

  public convenience init(
    dueTime: DispatchTimeInterval,
    latest: Bool = true,
    output: (@Sendable () async -> Void)? = nil
  ) where Value == Void {
    self.init(dueTime: dueTime, latest: latest, output: { _ in await output?() })
  }

  public func push(_ value: Value) {
    var shouldStartAThrottle = false

    os_unfair_lock_lock(self.lock)
    shouldStartAThrottle = self.stateMachine.newValue(value)
    os_unfair_lock_unlock(self.lock)

    if shouldStartAThrottle {
      self.task = Task { [weak self] in
        guard let self = self else { return }

        await withTaskGroup(of: Void.self) { group in
          loop: while true {
            try? await Task.sleep(nanoseconds: self.dueTime.nanoseconds)

            var hasTickedOutput: StateMachine.HasTickedOutput

            os_unfair_lock_lock(self.lock)
            hasTickedOutput = self.stateMachine.hasTicked()
            os_unfair_lock_unlock(self.lock)

            switch hasTickedOutput {
              case .finishThrottling:
                break loop
              case .continueThrottling(let first, let last):
                group.addTask {
                  await self.output?(self.latest ? last : first)
                }
                continue loop
            }
          }
        }
      }
    }
  }

  public func cancel() {
    self.task?.cancel()
  }

  deinit {
    self.cancel()
  }
}
