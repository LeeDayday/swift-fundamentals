protocol Animal {
    func speak() -> String
}

struct Dog: Animal {
    func speak() -> String { "Woof" }

    func fetch() {
        print("Fetching!")
    }
}

struct Cat: Animal {
    func speak() -> String { "Meow" }
}


// MARK: - 1. Existential Type

func makeAnyAnimal(_ isDog: Bool) -> any Animal {
    if isDog {
        return Dog()
    } else {
        return Cat()
    }
}

// MARK: - 2. Opaque Type

func makeSomeAnimal() -> some Animal {
    Dog()
}

// Error: 'some Animal' requires one underlying type.
// func makeInavlidAnimal(_ isDog: Bool) -> some Animal {
//     if isDog {
//         return Dog()
//     } else {
//         return Cat()
//     }
// }


// MARK: - 3. Public Interface

let opaqueAnimal = makeSomeAnimal()

print(opaqueAnimal.speak()) // Woof

// Error: fetch() is not part of Animal
// opaqueAnimal.fetch()

let concreteDog = Dog()
concreteDog.fetch() // Fetching!

// MARK: -4. Opaque Type Identity

func makeDogA() -> some Animal {
    Dog()
}

func makeDogB() -> some Animal {
    Dog()
}

let a = makeDogA()
let b = makeDogB()

// Different opque return types.
// let animals = [a, b] // Error

// Same opque return type.
let sameTypeAnimals = [makeDogA(), makeDogA()]

// Type erasure using an existential.
let mixedAnimals: [any Animal] = [
    makeDogA(),
    makeDogB(),
    Cat()
]

for animal in mixedAnimals {
    print(animal.speak())
}
