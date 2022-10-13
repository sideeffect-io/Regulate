//
//  Throttler.swift
//
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

import Foundation

public extension Task where Failure == Never {
  /// Creates a `Regulator` that executes the output with either the most-recent or first element
  /// pushed in the Throttler in the specified time interval
  ///   - dueTime: the interval at which to find and emit either the most recent or the first element
  ///   - latest: true if output should be called with the most-recent element, false otherwise
  ///   - output: the block to execute once the regulation is done
  /// - Returns: the throttled regulator
  static func throttle(
    dueTime: DispatchTimeInterval,
    latest: Bool = true,
    output: @Sendable @escaping (Success) async -> Void
  ) -> some Regulator<Success> {
    Throttler(dueTime: dueTime, latest: latest, output: output)
  }
}

/// Executes the output with either the most-recent or first element pushed in the Throttler in the specified time interval
///
/// ```swift
/// let throttler = Throttler<Int>(dueTime: .seconds(2), latest: true, output: { print($0) })
///
/// for index in (0...99) {
///   DispatchQueue.global().asyncAfter(deadline: .now().advanced(by: .milliseconds(100 * index))) {
///     // pushes a value every 100 ms
///     throttler.push(index)
///   }
/// }
///
/// // will only print an index once every 2 seconds (the latest received index before the `tick`)
/// ```
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
  public var dueTime: DispatchTimeInterval
  
  private let latest: Bool
  private let lock: os_unfair_lock_t = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
  private var stateMachine = StateMachine()
  private var task: Task<Void, Never>?

  public convenience init() {
    self.init(dueTime: .never, latest: true, output: nil)
  }

  /// A Regulator that emits either the most-recent or first element received during the specified interval
  /// - Parameters:
  ///   - dueTime: the interval at which to find and emit either the most recent or the first element
  ///   - latest: true if output should be called with the most-recent element, false otherwise
  ///   - output: the block to execute once the regulation is done
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
