actor Inventory {
    private var stock = 1

    // Mark: = Potential Issue

    func purchase() async -> Bool {
        guard stock > 0 else {
            return false
        }

        try? await Task.sleep(for: .seconds(1))

        stock -= 1
        return true
    }

    // Mark: - Improved Version

    func safePurchase() async -> Bool {
        try? await Task.sleep(for: .seconds(1))

        guard stock > 0 else {
            return false
        }

        stock -= 1
        return true
    }

    func remainingStock() -> Int {
        stock
    }
}

func run() async {
    let inventory = Inventory()

    async let first = inventory.purchase()
    async let second = inventory.purchase()

    let results = await (first, second)
    let remaining = await inventory.remainingStock()

    print(results)
    print(remaining)
}

func runSafe() async {
    let inventory = Inventory()

    async let first = inventory.safePurchase()
    async let second = inventory.safePurchase()

    let results = await (first, second)
    let remaining = await inventory.remainingStock()

    print(results)
    print(remaining)

}

await run()
await runSafe()
