//
//  Spy.swift
//  
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

import XCTest

actor Spy<Value> {
  var storage = [Value]()

  init() {}

  func push(_ value: Value) {
    self.storage.append(value)
  }

  func assertEqual(
    expected: [Value],
    file: StaticString = #filePath,
    line: UInt = #line
  ) where Value: Equatable {
    XCTAssertEqual(self.storage, expected, file: file, line: line)
  }
}
