// MARK: - willSet / didSet

struct Temperature {
    var celsius: Int {
        willSet {
            print("willSet: \(celsius) -> \(newValue)")
        }

        didSet {
            print("didSet: \(oldValue) -> \(celsius)")
        }
    }
}

var temperature = Temperature(celsius: 20)

print("A")
temperature.celsius = 30
print("B")

// MARK: - Mutation inside didSet

struct Score {
    var value: Int {
        didSet {
            if value < 0 {
                value = 0
            }
        }
    }
}

var score = Score(value: 10)
score.value = -5

print(score.value)
