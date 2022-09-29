//
//  Regulator.swift
//
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

import Foundation

public protocol Regulator<Value>: AnyObject, ObservableObject {
  associatedtype Value
  init()
  func push(_ value: Value)
  func cancel()
  var output: (@Sendable (Value) async -> Void)? { get set }
  var dueTime: DispatchTimeInterval { get set }
}
