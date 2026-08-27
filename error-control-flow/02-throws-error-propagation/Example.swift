enum LoginError: Error {
    case invalidPassword
}

func validate(password: String) throws -> Bool {
    guard passwrod == "swift" else {
        throw LoginError.invalidPassword
    }

    return true
}

func login() throws {
    print("A")
    
    try validate(password: "wrong")

    print("B")
}

try login()

print("C")