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
  @StateObject var bindingRegulator = Throttler<String>(dueTime: .seconds(1))

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
          .perform(regulator: bindingRegulator) { text in
            print("regulated text \(text)")
          }
      ) {
        Text("prompt")
      }
      .textFieldStyle(RoundedBorderTextFieldStyle())

    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
