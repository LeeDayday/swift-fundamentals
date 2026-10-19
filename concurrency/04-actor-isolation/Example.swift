actor BankAccount {
    private var balance = 100

    func deposit(_ amount: Int) {
        balance += amount
        print("Deposited: \(amount)")
    }

    func withdraw(_ amount: Int) -> Bool {
        guard balance >= amount else {
            return false
        }

        balance -= amount
        return true
    }

    func getBalance() -> Int {
        balance
    }
}

let account = BankAccount()

async let first: Bool = account.withdraw(80)
async let second: Bool = account.withdraw(80)

let results = await (first, second)
let balance = await account.getBalance()

print(results)
print(balance)

// MARK: - Actor Isolation & Access Control

// await account.balance
// Compile Error: 'balance' is inaccessible due to 'private'

// actor의 메서드가 async로 선언되지 않았더라도, 
// 외부에서 actor-isolated 메서드를 호출할 때
// await 이 필요할 수 있다.
