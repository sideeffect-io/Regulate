//
//  Button+Regulated.swift
//  
//
//  Created by Thibault Wittemberg on 30/09/2022.
//

#if canImport(SwiftUI)
import SwiftUI

public extension Button {
  /// Debounces the action of a Button
  /// - Parameter dueTime: the time the Debouncer should wait before executing the action
  /// - Returns: a debounced button
  func debounce(dueTime: DispatchTimeInterval) -> some View {
    return self.buttonStyle(RegulatedButtonStyle<Debouncer>(dueTime: dueTime))
  }

  /// Throttles the action of a Button
  /// - Parameter dueTime: the interval at which to execute the action
  /// - Returns: a throttled button
  func throttle(dueTime: DispatchTimeInterval) -> some View {
    return self.buttonStyle(RegulatedButtonStyle<Throttler>(dueTime: dueTime))
  }
}
#endif
