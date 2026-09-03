final class User {
    let name: String
    var subscription: Subscription?

    init(name: String) {
        self.name = name
    }

    deinit {
        print("User deinit")
    }
}

final class Subscription {
    unowned let user: User
    
    init(user: User) {
        self.user = user
    }

    func printOwner() {
        print(user.name)
    }

    deinit {
        print("Subscription deinit")
    }
}

final class WeakSubscription {
    weak var user: User?

    init(user: User) {
        self.user = user
    }

    func printOwner() {
        print(user?.name ?? "User is gone")
    }
}

var user: User? = User(name: "Dani")
let subscription = Subscription(user: user!)

user?.subscription = subscription

user = nil

subscription.printOwner()

