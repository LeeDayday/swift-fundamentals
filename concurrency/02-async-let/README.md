# async let

## Question

```swift
func loadProfile() async {
    async let user = fetchUser()
    async let image = fetchImage()

    print("loading")

    let result = await(user, image)
    print(result)
}
```

`async let` 은 일반적인 `await` 호출과 실행 흐름이 어떻게 다를까?

두 비동기 작업은 언제 시작되고, 현재 Task는 언제 결과를 기다리게 될까?

## My prediction

처음에는 `async let` 도 일반적인 비동기 작업과 마찬가지로 작업을 기다리는 동안 Thread를 다른 작업에 사용할 수 있게 만드는 문법이라고 생각했다.

하지만 `async let` 의 중요한 차이는 비동기 작업을 먼저 시작하고 결과는 나중에 기다릴 수 있다는 것이었다.

## Principle

### Sequential await

```swift
let user = await fetchUser()
let image = await fetchImage()
```

첫 번째 호출의 결과가 준비되지 않았다면 현재 Task는 `await` 에서 suspend 될 수 있다.

따라서 현재 Task가 재개되어 다음 줄에 도달한 뒤에야 `fetchImage()` 가 호출된다.

```text
fetchUser  ██████████
                      fetchImage █████
```

두 함수가 모두 `async` 라고 해서 자동으로 동시에 진행되는 것은 아니다.

### async let

```swift
async let user = fetchUser()
async let image = fetchImage()
```

`async let` 은 비동기 작업을 시작하고, 그 결과를 나중에 `await` 하여 사용할 수 있도록 선언한다.

따라서 첫 번째 작업의 결과를 기다린 뒤 두 번째 작업을 시작할 필요가 없다.

```text
fetchUser   ███████████████
fetchImage  ████████
```

두 작업의 진행 시간을 겹칠 수 있다.

### Waiting for Results

```swift
async let user = fetchUser()
async let image = fetchImage()

print("loading")

let result = await (user, image)
```

loading 을 출력하기 위해서는 user 와 image 의 결과가 필요하지 않다.

따라서 결과를 기다리지 않고 실행할 수 있다.

반면:

```swift
let result = await (user, image)
```

에서는 두 값이 모두 필요하다.

둘 중 하나가 먼저 완료되더라도 나머지 결과까지 준비되어야 result 를 만들고 다음 코드로 진행할 수 있다.

### Child Task

async let 으로 시작한 비동기 작업은 현재 Task에 구조적으로 연결된 child task로 동작한다.

```text
Parent Task
    │
    ├── user Child Task
    │
    └── image Child Task
```

child task는 부모의 실행 구조와 생애주기에 묶여 있다.

부모 Task의 취소는 child task에도 전파될 수 있다.

이러한 구조는 Swift의 Structured Concurrency와 연결된다.

## Important Distinction

```text
await
- 비동기 작업의 결과가 필요한 지점
- 결과가 준비되지 않았다면 현재 Task 가 suspend 될 수 있음

async let
- 비동기 작업을 먼저 시작
- child task로 실행
- 결과는 나중에 await

async != concurrent
- async 함수라고 자동으로 동시에 진행되는 것은 아님

async let
- 서로 독립적인 비동기 작업의 진행을 겹치도록 구성할 수 있음
```

## Takeaway

다음 코드를 보면:

```swift
let user = await fetchUser()
let image = await fetchImage()
```

각 작업이 순차적으로 시작되는 구조인지 확인한다.

반면:

```swift
async let user = fetchUser()
async let image = fetchImage()

let result = await (user, image)
```

에서는 다음을 확인한다.

1. 어떤 비동기 작업들이 먼저 시작되는가?
2. 실제 결과가 필요한 await 지점은 어디인가?
3. 각 child task가 어느 부모 task 의 생애주기에 속하는가?

`async let` 은 단순히 "더 빠르게 실행하는 문법" 이라기 보다,
**서로 독립적인 비동기 작업을 먼저 시작하고 결과가 필요한 시점에 기다리도록 구조화하는 방법**으로 이해한다.