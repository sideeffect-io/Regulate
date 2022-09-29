# Regulate

**Regulate** is a lightweight library that brings the following time-based regulation operations for things that can emit values over times (and are not using reactive programming or `AsyncSequence`).

- [Debounce](./Sources/Debouncer.swift) (Outputs elements only after a specified time interval elapses between events)
- [Throttle](./Sources/Throttler.swift) (Outputs either the most-recent or first element pushed by a producer in the specified time interval)

**Regulate** is entirely backed by Swift concurrency and limits the number of created `Tasks` to the minimum.

**Regulate** also provides SwiftUI helpers to regulate buttons and bindings out of the box.
You can give a look at the [Sample app](./Sample).

For a Button, it is as simple as:

```swift
Button {
  print("I've been hit (throttled)!")
} label: {
  Text("Hit me")
}
.throttle(dueTime: .seconds(1))
```

For a Binding, there is a tiny bit of extra work:

```swift
@State private var text = ""
@StateObject private var debouncer = Debouncer<String>(dueTime: .seconds(1))
...
TextField(
  text: self
    .$text
    .perform(regulator: debouncer) { text in
      print("regulated text \(text)") // you can perform any side effect here!
    }
) {
  Text("prompt")
}
```

## Demo

<kbd>
<img style="border:2px solid black" alt="Demo Application" src="https://raw.githubusercontent.com/sideeffect-io/Regulate/main/Regulate.gif"/>
</kbd>

## Adding Regulate as a Dependency

To use the `Regulate` library in a SwiftPM project, 
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/sideeffect-io/Regulate"),
```

Include `"Regulate"` as a dependency for your executable target:

```swift
.target(name: "<target>", dependencies: ["Regulate"]),
```

Finally, add `import Regulate` to your source code.
