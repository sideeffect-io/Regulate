//
//  Debouncer.swift
//
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

import Foundation

public extension Task where Failure == Never {
  /// Creates a `Regulator` that executes an output only after a specified time interval elapses between events
  /// - Parameters:
  ///   - dueTime: the time the Debouncer should wait before executing the output
  ///   - output: the block to execute once the regulation is done
  /// - Returns: the debounced regulator
  static func debounce(
    dueTime: DispatchTimeInterval,
    output: @Sendable @escaping (Success) async -> Void
  ) -> some Regulator<Success> {
    Debouncer(dueTime: dueTime, output: output)
  }
}

/// Executes an output only after a specified time interval elapses between events
///
/// ```swift
/// let debouncer = Debouncer<Int>(dueTime: .seconds(2), output: { print($0) })
///
/// for index in (0...99) {
///   DispatchQueue.global().asyncAfter(deadline: .now().advanced(by: .milliseconds(100 * index))) {
///     // pushes a value every 100 ms
///     debouncer.push(index)
///   }
/// }
///
/// // will only print "99" 2 seconds after the last call to `push(_:)`
/// ```
public final class Debouncer<Value>: @unchecked Sendable, ObservableObject, Regulator {
  struct DueValue {
    let value: Value
    let dueTime: DispatchTime
  }

  struct StateMachine {
    enum State {
      case idle
      case debouncing(value: DueValue, nextValue: DueValue?)
    }

    var state: State = .idle

    mutating func newValue(_ value: DueValue) -> Bool {
      switch self.state {
        case .idle:
          self.state = .debouncing(value: value, nextValue: nil)
          return true
        case .debouncing(let current, _):
          self.state = .debouncing(value: current, nextValue: value)
          return false
      }
    }

    enum HasDebouncedOutput {
      case continueDebouncing(DueValue)
      case finishDebouncing
    }

    mutating func hasDebouncedCurrentValue() -> HasDebouncedOutput {
      switch self.state {
        case .idle:
          fatalError("inconsistent state, a value was being debounced")
        case .debouncing(_, nextValue: .some(let nextValue)):
          state = .debouncing(value: nextValue, nextValue: nil)
          return .continueDebouncing(nextValue)
        case .debouncing(_, nextValue: .none):
          state = .idle
          return .finishDebouncing
      }
    }
  }

  public var output: (@Sendable (Value) async -> Void)?
  public var dueTime: DispatchTimeInterval

  private let lock: os_unfair_lock_t = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
  private var stateMachine = StateMachine()
  private var task: Task<Void, Never>?

  public convenience init() {
    self.init(dueTime: .never, output: nil)
  }

  /// A Regulator that executes the output only after a specified time interval elapses between events
  /// - Parameters:
  ///   - dueTime: the time the Debouncer should wait before executing the output
  ///   - output: the block to execute once the regulation is done
  public init(
    dueTime: DispatchTimeInterval,
    output: (@Sendable (Value) async -> Void)? = nil
  ) {
    self.lock.initialize(to: os_unfair_lock())
    self.dueTime = dueTime
    self.output = output
  }

  public func push(_ value: Value) {
    let newValue = DueValue(value: value, dueTime: DispatchTime.now().advanced(by: dueTime))
    var shouldStartADebounce = false

    os_unfair_lock_lock(self.lock)
    shouldStartADebounce = self.stateMachine.newValue(newValue)
    os_unfair_lock_unlock(self.lock)

    if shouldStartADebounce {
      self.task = Task { [weak self] in
        guard let self = self else { return }

        var timeToSleep = self.dueTime.nanoseconds
        var currentValue = value

      loop: while true {
        try? await Task.sleep(nanoseconds: timeToSleep)

        var output: StateMachine.HasDebouncedOutput
        os_unfair_lock_lock(self.lock)
        output = self.stateMachine.hasDebouncedCurrentValue()
        os_unfair_lock_unlock(self.lock)

        switch output {
          case .finishDebouncing:
            break loop
          case .continueDebouncing(let value):
            timeToSleep = DispatchTime.now().distance(to: value.dueTime).nanoseconds
            currentValue = value.value
            continue loop
        }
      }

        await self.output?(currentValue)
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
