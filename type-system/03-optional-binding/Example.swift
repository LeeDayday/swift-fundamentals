struct User {
    let name: String
}

func findUser(id: Int) -> User? {
    if id == 1 {
        return User(name: "Dani")
    }

    return nil
}

let user = findUser(id: 1)

print(type(of: user))

if let user {
    print(type(of: user))
    print(user.name)
}

print(type(of: user))

// User? is shorthand for Optional<User>
// 
// Optional<User>
// ├── .none
// └── .some(User)
