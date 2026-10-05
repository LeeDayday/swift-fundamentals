enum LoginError: Error {
    case invalidPassword
}

struct User {
    let name: String
}

func login(password: String) -> Result<User, LoginError> {
    guard password == "swift" else {
        return .failure(.invalidPassword)
    }

    return .success(User(name: "Dani"))
}

let result = login(password: "wrong")

print("A")

switch result {
    case .success(let user):
        print("Welcome, \(user.name)")

    case .failure(let error):
        print("Login failed: \(error)")
}

print("B")

// MARK: - Store results and handle them later

let results: [Result<User, LoginError>] = [
    login(password: "wrong"),
    login(password: "swift"),
    login(password: "wrong")
]

for result in results {
    switch result {
        case .success(let user):
            print("Welcome, \(username)")
        
        case .failure(let error):
            print("Login failed: \(error)")
    }
}
