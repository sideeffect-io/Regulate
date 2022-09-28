//
//  DispatchTimeInterval+Nanoseconds.swift
//  Debounce
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

import Foundation

extension DispatchTimeInterval {
  var nanoseconds: UInt64 {
    switch self {
      case .nanoseconds(let value) where value >= 0: return UInt64(value)
      case .microseconds(let value) where value >= 0: return UInt64(value) * 1000
      case .milliseconds(let value) where value >= 0: return UInt64(value) * 1_000_000
      case .seconds(let value) where value >= 0: return UInt64(value) * 1_000_000_000
      case .never: return .zero
      default: return .zero
    }
  }
}
