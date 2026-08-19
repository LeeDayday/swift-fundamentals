//
//  Example.swift
//  
//
//  Created by Dayoon Lee on 8/19/26.
//

class Animal {
    func sound() {
        print("Animal sound")
    }
}

class Dog: Animal {
    override func sound() {
        print("Woof")
    }

    func fetch() {
        print("Fetch")
    }
}

func describe(_ animal: Animal) {
    print("Animal")
}

func describe(_ dog: Dog) {
    print("Dog")
}

let dog = Dog()
let animal: Animal = dog

describe(dog)
describe(animal)

dog.sound()
animal.sound()
