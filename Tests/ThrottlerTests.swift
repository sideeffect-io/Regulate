//
//  ThrottlerTests.swift
//  
//
//  Created by Thibault Wittemberg on 28/09/2022.
//

@testable import Regulate
import XCTest

final class ThrottlerTests: XCTestCase {
  func test_throttler_outputs_first_value_per_time_interval() async {
    let hasThrottledTwoValues = expectation(description: "Has throttled 2 values")
    hasThrottledTwoValues.expectedFulfillmentCount = 2

    let spy = Spy<Int>()

    let sut = Throttler<Int>(dueTime: .milliseconds(100), latest: false) { value in
      await spy.push(value)
      hasThrottledTwoValues.fulfill()
    }

    //               T                 T
    // 0 -- 40 -- 80 -- 120 -- 160 ---------
    for index in (0...4) {
      DispatchQueue.global().asyncAfter(deadline: .now().advanced(by: .milliseconds(40 * index))) {
        sut.push(index)
      }
    }

    wait(for: [hasThrottledTwoValues], timeout: 5.0)

    await spy.assertEqual(expected: [0, 3])
  }

  func test_throttler_outputs_last_value_per_time_interval() async {
    let hasThrottledTwoValues = expectation(description: "Has throttled 2 values")
    hasThrottledTwoValues.expectedFulfillmentCount = 2

    let spy = Spy<Int>()

    let sut = Throttler<Int>(dueTime: .milliseconds(100), latest: true) { value in
      await spy.push(value)
      hasThrottledTwoValues.fulfill()
    }

    //               T                 T
    // 0 -- 40 -- 80 -- 120 -- 160 ---------
    for index in (0...4) {
      DispatchQueue.global().asyncAfter(deadline: .now().advanced(by: .milliseconds(40 * index))) {
        sut.push(index)
      }
    }

    wait(for: [hasThrottledTwoValues], timeout: 5.0)

    await spy.assertEqual(expected: [2, 4])
  }

  func test_throttler_outputs_last_value_per_time_interval_when_no_last() async {
    let hasThrottledTwoValues = expectation(description: "Has throttled 2 values")
    hasThrottledTwoValues.expectedFulfillmentCount = 2

    let spy = Spy<Int>()

    let sut = Throttler<Int>(dueTime: .milliseconds(100), latest: true) { value in
      await spy.push(value)
      hasThrottledTwoValues.fulfill()
    }

    //               T                 T
    // 0 -- 40 -- 80 -- 120 ----------------
    for index in (0...3) {
      DispatchQueue.global().asyncAfter(deadline: .now().advanced(by: .milliseconds(40 * index))) {
        sut.push(index)
      }
    }

    wait(for: [hasThrottledTwoValues], timeout: 5.0)

    await spy.assertEqual(expected: [2, 3])
  }
}
