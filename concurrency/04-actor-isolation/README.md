# Actor Isolation

## Question

```swift
actor BankAccount {
    private var balance = 100

    func withdraw(_ amount: Int) -> Bool {
        guard balance >= amount else {
            return false
        }

        balance -= amount
        return true
    }
}

let account = BankAccount()

async let first = account.withdraw(80)
async let second = account.withdraw(80)

let results = await (first, second)
```

두 Task 가 동일한 `balance` 에 접근하여 출금을 시도한다.
- 두 출금 작업이 모두 성공할 수 있을까?
- `actor` 는 공유 상태에 대한 접근을 어떻게 관리할까?

## My Prediction

`actor` 는 여러 Task 가 공유하는 자원을 안전하게 관리하기 위한 구조라고 예상했다.

두 작업이 각각 80을 출금하므로 첫 번째 작업은 성공하고, 두 번째 작업은 실패할 것이라고 생각했다.

```swift
results = (true, false)
balance = 20
```

하지만 `async let` 의 선언 순서가 실제 실행 순서를 보장하지는 않는다.

따라서 다음 두 결과가 모두 가능하다.

```swift
(true, false)
(false, true)
```

최종 잔액은 두 경우 모두 20이다.

## What I Missed

`async let` 으로 먼저 선언한 Task 가 반드시 먼저 실행되는 것은 아니다.

Task의 생성 순서와 실제 실행 순서는 구분해야 한다.

또한 `actor` 는 작업의 실행 순서를 보장하는 것이 아니라, 격리된 상태에 대한 접근을 조정한다.

## Principle

### Actor

`actor` 는 공유되는 가변 상태를 격리하여 여러 Task 가 안전하게 접근할 수 있도록 하는 Swift의 reference type 이다.

```swift
actor BankAccount {
    private var balance = 100
}
```

Actor Isolation 은 여러 Task 가 동일한 가변 상태에 충돌하는 방식으로 접근하여 발생하는 data race 를 방지한다.

### Race Condition

일반적인 class 에서 별도의 동기화 없이 두 Task 가 동시에 출금을 수행한다고 가정해보자.

```swift
guard balance >= amount else {
    return false
}

balance -= amount
```

다음 상황이 발생할 수 있다.

```text
Task A                  Task B
   │                       │
balance = 100          balance = 100
   │                       │
guard 통과             guard 통과
   │                       │
balance -= 80          balance -= 80
```

두 작업이 모두 잔액이 충분하다고 판단할 수 있다.

이는 조건 검사와 실제 상태 변경 사이에 다른 작업이 개입할 수 있기 떄문이다.

guard 로 조건을 검사하는 것만으로 동시 접근 문제가 해결되지는 않는다.

### Actor Isolation

```swift
actor BankAccount {
    private var balance = 100

    func withdraw(_ amount: Int) -> Bool {
        guard balance >= amount else {
            return false
        }

        balance -= amount
        return true
    }
}
```

현재 `withdraw()` 내부에는 suspension point 가 없다.

따라서 한 Task 가 이 actor-isolated 메서드를 실행하는 동안 다른 Task 가 같은 actor의 격리된 상태에 접근해 중간에 값을 변경하지 못한다.

조건 검사와 상태 변경이 다른 Task의 개입 없이 진행될 수 있다.

단, actor의 모든 메서드가 항상 처음부터 끝가지 원자적으로 실행된다는 의미는 아니다.

메서드 내부에 await 이 있다면 Actor Reentrancy를 별도로 고려해야 한다.

### Actor Isolation & await

```swift
actor BankAccount {
    var balance = 100
}

let account = BankAccount()
let current = await account.balance
```

Actor 외부에서 actor-isolated 상태에 접근할 때는 `await` 이 필요할 수 있다.

`balance` 자체는 async property 가 아니다.

하지만 외부 Task 가 actor의 격리된 실행 맥락에 접근하는 과정에서 suspend 될 수 있으므로 `await` 이 사용된다.

즉:
> await 은 async 함수 호출에서만 사용하는 것이 아니라, actor isolation 경계를 넘어 접근할 때도 필요할 수 있다.

### Actor Isolation vs Access Control

두 개념은 서로 다른 문제를 해결한다.

|  | Actor Isolation | Access Control |
| -- | -- | -- |
| 목적 | 동시 접근으로 인한 data race 방지 | 외부에 공개할 인터페이스 제한 |
| 핵심 질문 | 어떤 실행 맥락에서 접근하는가? | 코드의 어느 범위에서 접근 가능한가? |
| 관련 요소 | `actor`, `await` | `private`, `internal`, `public` |

```swift
actor BankAccount {
    private var balance = 100

    func getBalance() -> Int {
        balance
    }
}
```

`private` 은 외부 코드가 balance 에 직접 접근하지 못하게 막는다.

`actor` 는 허용된 메서드들이 격리된 상태에 안전하게 접근하도록 조정한다.

따라서 `private` 과 `actor` 는 서로를 대체하는 기능이 아니다.

## Important Distinction

```text
Actor
- 공유되는 가변 상태를 격리
- Data race 방지

async let
- 여러 child task 를 시작
- 실행 순서는 보장하지 않음

Actor Isolation
- 격리된 상태에 대한 접근을 조정
- 외부 접근에서 await 이 필요할 수 있음

Access Control
- 코드의 접근 범위를 제한
- private 등으로 외부 인터페이스 관리
```

## Takeaway

`actor` 를 사용하는 코드를 볼 때 다음을 확인한다.

1. 어떤 가변 상태가 actor 내부에 격리되어 있는가?
2. 여러 Task 가 동일한 상태에 접근할 가능성이 있는가?
3. 외부에서 actor isolation 경계를 넘어 접근하는가?
4. Actor Isolation 과 Access Control 이 각각 어떤 역할을 하는가?

한 줄로 정리하면:
> Actor 는 작업의 실행 순서를 보장하는 것이 아니라, 격리된 상태에 대한 접근을 조정하여 data race를 방지한다.