struct Counter {
    var value: Int

    mutating func increment() {
        value += 1
    }
}

final class Dashboard {
    var counter: Counter

    init(counter: Counter) {
        self.counter = counter
    }

    func increase() {
        counter.increment()
    }
}

var original = Counter(value: 0)
let dashboard = Dashboard(counter: original)

dashboard.increase()
original.increment()

print(original.value) // 1
print(dashboard.counter.value) // 1

// MARK: - let with Value Type / Reference Type

struct StructCounter {
    var value = 0

    mutating func increment() {
        value += 1
    }
}

final class ClassCounter {
    var value = 0

    func increment() {
        value += 1
    }
}

let structCounter = StructCounter()
let classCounter = ClassCounter()

// structCounter.increment() // Compile Error
classCounter.increment() // OK