//
//  ContentView.swift
//  Sample
//
//  Created by Thibault Wittemberg on 30/09/2022.
//

import SwiftUI
import Regulate

struct ContentView: View {
  @State var throttledCounter = 0
  @State var debouncedCounter = 0
  @State var text = ""
  @State var isOn = false
  @State var steps = 0
  @StateObject var textRegulator = Throttler<String>(dueTime: .seconds(1))
  @StateObject var toggleRegulator = Debouncer<Bool>(dueTime: .seconds(1))
  @StateObject var stepperRegulator = Debouncer<Int>(dueTime: .seconds(1))

  var body: some View {
    VStack {
      HStack {
        Button {
          print("I've been hit (throttled)!")
          self.throttledCounter += 1
        } label: {
          Text("Hit me (throttled)")
        }
        .throttle(dueTime: .seconds(1))
        .buttonStyle(BorderedProminentButtonStyle())
        .padding()

        Text("\(throttledCounter)")
          .padding()
      }
      .padding()

      HStack {
        Button {
          print("I've been hit (debounced)!")
          self.debouncedCounter += 1
        } label: {
          Text("Hit me (debounced)")
        }
        .debounce(dueTime: .seconds(1))
        .buttonStyle(BorderedProminentButtonStyle())
        .padding()

        Text("\(debouncedCounter)")
          .padding()
      }

      TextField(
        text: self
          .$text
          .perform(regulator: textRegulator) { text in
            print("regulated text \(text)")
          }
      ) {
        Text("prompt")
      }
      .textFieldStyle(RoundedBorderTextFieldStyle())

      Toggle(
        isOn: self
          .$isOn
          .perform(regulator: toggleRegulator) { value in
            print("regulated toggle \(value)")
          }
      ) {
        Text("Regulated toogle")
      }

      Stepper(
        "Regulated stepper \(self.steps)",
        value: self
          .$steps
          .perform(regulator: stepperRegulator) { value in
            print("regulated stepper \(value)")
          }
      )
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
