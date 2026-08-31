func fetchUser() async -> String {
    print("user start")

    try? await Task.sleep(for: .seconds(2))

    print("user end")
    return "Dani"
}

func fetchImage() async -> String {
    print("image start")

    try? await Task.sleep(for: .seconds(1))

    print("image end")
    return "profile.png"
}

func loadProfile() async {
    async let user = fetchUser()
    async let image = fetchImage()

    print("loading")

    let result = await (user, image)
    print(result)
}

Task {
    await loadProfile()
}

// Sequential

// let user = await fetchUser()
// let image = await fetchImage()

// fetchUser의 결과를 얻은 뒤에야
// fetchImage가 시작된다


// Concurrent

// async let user = fetchUser()
// async let image = fetchImage()

// 두 작업을 먼저 시작하고,
// 결과가 필요한 시점에 await한다.
