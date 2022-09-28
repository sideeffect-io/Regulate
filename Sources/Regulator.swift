//
//  Regulator.swift
//  Debounce
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

public protocol Regulator<Value>: AnyObject {
  associatedtype Value
  var output: (@Sendable (Value) async -> Void)? { get set }
  func push(_ value: Value)
  func cancel()
}
