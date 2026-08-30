# async/await & Suspension

## Question

```swift
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
```

`await` 을 만나 비동기 작업의 결과를 기다려야 할 때
현재 Task 와 Thread 에는 각각 어떤 일이 일어날까?

그리고 `async` 함수 여러 개를 호출하면 자동으로 동시에 실행될까?

## My prediction

처음에는 `loadProfile()` 과 `fetchUser()` 가 각각 별도의 Thread에서 실행될 수 있다고 생각했다.

또한 `async` 함수 여러 개를 호출하면 각 작업이 비동기적으로 실행되므로 동시에 진행될 수 있다고 생각했다.

## What I Missed

`async 함수 = 별도의 Thread` 가 아니다.

또한 비동기적으로 실행할 수 있다는 것과 여러 작업이 동시에 진행된다는 것은 같은 의미가 아니다.

```swift
let user = await fetchUser()
let image = await fetchImage()
```

첫 번째 `await` 에서 현재 Task가 suspend되면 아직 다음 줄까지 실행이 도달하지 않았다.

따라서 `fetchUser()` 의 결과가 준비되고 현재 Task가 재개된 뒤에야 `fetchUser()` 가 호출된다.

## Principle

### async

```swift
func fetchUser() async -> String
```

함수가 비동기 작업을 수행할 수 있음을 나타낸다.

`async` 라고 해서 새로운 Thread가 생성되거나 다른 async 함수와 자동으로 동시에 실행되는 것은 아니다.

### await

```swift
let user = await fetchUser()
```

비동기 작업의 결과가 필요한 지점을 나타낸다.

결과가 아직 준비되지 않았다면 현재 Task는 이 지점에서 suspend될 수 있다.

`await` 이후의 코드는 현재 Task가 다시 실행될 수 있을 때까지 진행되지 않는다.

### Suspension

Suspension은 현재 Task의 실행을 잠시 멈추는 것이다.

```text
Task 실행
   ↓
await
   ↓
결과가 아직 준비되지 않음
   ↓
Task suspend
   ↓
결과 준비
   ↓
Task resume
   ↓
await 이후 코드 실행
```

Task가 suspend되더라도 이를 실행하던 Thread를 붙잡고 기다리는 것은 아니다.
Thread는 그동안 다른 실행 가능한 Task를 수행할 수 있다.

### Task vs Thread


```text
Task
- 비동기 작업의 실행 단위

Thread
- 실제 코드를 실행하는 실행 자원
```

Task와 Thread는 1:1 관계가 아니다.

Task가 suspend되면 Thread는 다른 작업에 사용될 수 있으며, Task 가 resume 될 때 반드시 이전과 같은 Thread에서 실행된다고 가정해서는 안 된다.

### Asynchrony vs Concurrency

비동기와 동시성은 같은 개념이 아니다.

#### Asynchrony

작업의 결과를 기다려야 할 때 현재 실행 자원을 붙잡고 기다리지 않을 수 있도록 한다.

#### Concurrency

여러 작업의 진행을 서로 겹쳐 다룰 수 있도록 한다.

따라서:

```swift
let user = await fetchUser()
let image = await fetchImage()
```

두 함수가 모두 async 이더라도 이 코드는 두 작업을 순차적으로 시작한다.

```text
fetchUser  ██████████
                      fetchImage ██████████
```

async/await 자체가 여러 작업의 동시 실행을 의미하지 않는다.

## Important Distinction

```text
async
- 비동기 함수를 선언

await
- 현재 Task가 suspend될 수 있는 지점

suspension
- Task의 실행이 잠시 중단될 수 있음
- Thread를 붙잡고 기다리는 것은 아님

Task != Thread
- Task와 Thread는 1:1로 대응하지 않음

Asynchrony != Concurrency
- async 작업이라고 자동으로 동시에 실행되는 것은 아님
```

## Takeaway

`await` 을 볼 때:
> "이 Thread가 여기서 기다린다."
라고 생각하지 않는다.

대신:
> "결과가 준비되지 않았다면 현재 Task가 여기서 suspend될 수 있다."
라고 읽는다.

또한 `async` 를 보고:
> "새로운 Thread에서 실행된다."
> "다른 async 작업과 동시에 실행된다."
고 가정하지 않는다.

코드를 읽을 때 다음을 구분한다.

1. 어느 시점에서 현재 Task가 suspend될 수 있는가?
2. suspend되는 동안 Thread는 어떻게 사용될 수 있는가?
3. 여러 비동기 작업이 실제로 동시에 시작되는 구조인가?
