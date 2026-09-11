protocol IdentifiableItem {
    var id: Int { get }
}

struct User: IdentifiableItem {
    let id: Int
    let name: String
}

struct Product: IdentifiableItem {
    let id: Int
    let title: String
}

// MARK: - Generic

func find<T: IdentifiableItem>(
    id: Int,
    in items: [T]
) -> T? {
    for item in items {
        if item.id == id {
            return item
        }
    }

    return nil
}

let users = [
    User(id: 1, name: "Dani"),
    User(id: 2, name: "Mina")
]

let result = find(id: 2, in: users)

// result: User?
print(result?.name ?? "Not found")

// MARK: - Existential

let item: any IdentifiableItem = User(id: 1, name: "Dani")

print(item.id)
// print(item.name) // Compile Error
