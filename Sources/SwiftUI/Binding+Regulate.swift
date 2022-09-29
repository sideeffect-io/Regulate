//
//  Binding+Regulate.swift
//  
//
//  Created by Thibault Wittemberg on 30/09/2022.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public extension Binding {
  init(
    regulator: some Regulator<Value>,
    get: @escaping () -> Value,
    set: @Sendable @escaping (Value) async -> Void
  ) {
    regulator.output = set
    self.init(get: get) { value in
      regulator.push(value)
    }
  }

  /// Applies the specified regulator to the execution block
  /// every time the binding is set.
  /// - Parameters:
  ///   - regulator: the regulator to apply to the binding input
  ///   - block: the block to execute once the regulation has applied
  /// - Returns: the Binding wrapping the base binding
  func perform(
    regulator: some Regulator<Value>,
    _ block: @Sendable @escaping (Value) async -> Void
  ) -> Self {
    regulator.output = block

    return Binding {
      self.wrappedValue
    } set: { value in
      self.wrappedValue = value
      regulator.push(value)
    }
  }
}
#endif
