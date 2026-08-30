func fetchUser() async -> String {
    print("2. fetch start")

    try? await Task.sleep(for: .seconds(1))

    print("3. fetch end")
    return "Dani"
}

func loadProfile() async {
    print("1. load start")

    let name = await fetchUser()

    print("4. user: \(name)")
}

Task {
    await loadProfile()
    print("5. task end")
}

print("6. outside")

// MARK: - Sequential async calls

func loadContent() async {
    let user = await fetchUser()
    let image = await fetchImage()

    print(user, image)
}
