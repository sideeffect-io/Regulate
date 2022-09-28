# Regulate

**Regulate** is a lightweight library that brings the following time-based regulation operations for things that can emit values over times (and are not from reactive programming or `AsyncSequence`).

- debounce:
- throttle:

**Regulate** is entirely backed by Swift concurrency and limits the number of created `Tasks` to the minimum.

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
