func process(_ value: Int) {
    print("A")

    defer {
        print("B")
    }

    guard value > 0 else {
        print("C")
    }

    print("D")
}

process(-1)
print("E")
