//
//  RegulatedButtonStyle.swift
//  
//
//  Created by Thibault Wittemberg on 30/09/2022.
//

#if canImport(SwiftUI)
import SwiftUI

public struct RegulatedButtonStyle<R: Regulator<Void>>: PrimitiveButtonStyle {
  @StateObject var regulator = R.init()
  let dueTime: DispatchTimeInterval

  init(dueTime: DispatchTimeInterval) {
    self.dueTime = dueTime
  }

  public func makeBody(configuration: Configuration) -> some View {
    regulator.dueTime = self.dueTime
    regulator.output = { _ in configuration.trigger() }

    if #available(iOS 15.0, *) {
      return Button(role: configuration.role) {
        regulator.push(())
      } label: {
        configuration.label
      }
    } else {
      return Button {
        regulator.push(())
      } label: {
        configuration.label
      }
    }
  }
}
#endif
