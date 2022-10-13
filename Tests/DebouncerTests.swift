//
//  DebouncerTests.swift
//  
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

@testable import Regulate
import XCTest

final class DebouncerTests: XCTestCase {
  func test_debouncer_discards_intermediates_values_and_outputs_last_value() async {
    let hasDebounced = expectation(description: "Has debounced a value")
    let spy = Spy<Int>()

    let sut = Task.debounce(dueTime: .milliseconds(200)) { value in
      await spy.push(value)
      hasDebounced.fulfill()
    }

    for index in (0...4) {
      DispatchQueue.global().asyncAfter(deadline: .now().advanced(by: .milliseconds(100 * index))) {
        sut.push(index)
      }
    }

    wait(for: [hasDebounced], timeout: 5.0)

    await spy.assertEqual(expected: [4])
  }
}
