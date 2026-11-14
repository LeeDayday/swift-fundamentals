import Foundation

@MainActor
final class ProfileStore {
    private var name = "Dani"

    func load() {
        print("A")

        // Inherits MainActor isolation
        Task {
            print("B")
            updateName("Mina")
        }

        // Does not inherit MainActor isolation
        Task.detached {
            print("C")
            await self.updateName("Alex")
        }

        // Explicitly isolated to MainActor
        Task.detached { @MainActor in
            print("E")
            self.updateName("Bob")
        }

        print("D")
    }

    private func updateName(_ value: String) {
        name = value
        print("Updated: \(name)")
    }
}

@MainActor
func run() {
    let store = ProfileStore()
    store.load()
}

await run()
