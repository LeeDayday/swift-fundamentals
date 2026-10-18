# Task Cancellation

## Question

```swift
func download() async {
    print("download start")

    for step in 1...5 {
        try? await Task.sleep(for: .seconds(1))
        print("step \(step)")
    }

    print("download end")
}

let task = Task {
    await download()
}
```

`task.cancel()` 을 호출하면 실행 중인 Task는 즉시 종료될까?

그리고 Task 내부에서는 취소 요청을 어떻게 실제 실행 종료로 연결할 수 있을까?

## My Prediction

처음에는 

```swift
let task = Task {
    await download()
}
```

가 `download()` 가 끝날 때까지 기다리는 코드라고 생각했다.

따라서 바깥의 

```swift
task.cancel()
```
에 도달했을 때는 이미 `download()` 가 끝났을 것이라고 예상했다.

하지만 `Task { ... }` 는 새로운 Task 를 만들고 실행을 시작하며, 바깥의 현재 Task 는 다음 코드로 계속 진행할 수 있다.

## Principle

### Task 생성

```swift
let task = Task {
    await download()
}
```

새로운 Task를 생성하고 실행을 시작한다.

`task` 에는 생성된 Task를 취소하거나 결과를 기다리는 등에 사용할 수 있는 handle이 저장된다.

별도의 `start()` 호출은 필요하지 않다.

```text
현재 Task
│
├─ 새로운 Task 생성 ──→ download()
│
└─ 다음 코드 계속 실행
```

### Task.sleep

```swift
try await Task.sleep(for: .seconds(1))
```

`Task.sleep` 은 호출하고 있는 현재 Task 를 suspend 할 수 있는 async 함수다.

따라서 서로 다른 Task에서 호출한 Task.sleep은 각각 그 호출이 실행되고 있는 Task의 흐름에 영향을 준다.

### Cooperative Cancellation

```swift
task.cancel()
```

은 실행 중인 Task를 그 자리에서 강제로 종료하는 명령이 아니다.

Task에 취소가 요청되었다는 상태를 전달한다.

```text
외부
  │
  │ task.cancel()
  ▼
Task
  │
  │ cancellation requested
  ▼
Task 내부 코드가 취소를 감지
  │
  ▼
적절한 종료 처리
```

Task 가 취소 요청에 반응하도록 작성되어야 실제 실행 종료로 이어질 수 있다.

이를 cooperative cancellation으로 이해할 수 있다.

### Why Not Force Stop?

Task를 임의의 지점에서 강제로 종료하면 작업이 중간 상태로 남을 수 있다.

예를 들어:

```swift

balance -= 10

// 여기서 강제 종료

saveBalance()
```

처럼 상태 변경과 후속 처리가 분리되어 있다면, 중간에 강제로 실행을 끊는 것은 일관되지 않은 상태를 만들 수 있다.

따라서 Task가 적절한 지점에서 취소를 확인하고 스스로 종료 흐름을 선택할 수 있도록 한다.

### Cancellation Check

Task 내부에서는 취소 여부를 직접 확인할 수 있다.

```swift
if Task.isCancelled {
    return
}
```

또는:

```swift
try Task.checkCancellation()
```

처럼 취소된 경우 오류를 던지도록 할 수도 있다.

### Task.sleep 과 Cancellation

`Task.sleep` 은 취소에 반응할 수 있으며, 취소되면 오류를 던질 수 있다.

따라서:

```swift
try? await Task.sleep(for: .seconds(1))
```

처럼 작성하면 발생한 오류가 nil 로 변환된다.

그 결과 취소 요청이 있었더라도 다음 코드로 계속 진행할 수 있다.

```swift
try? await Task.sleep(for: .seconds(1))

print("step")
// 계속 실행될 수 있음
```

### Handling Cancellation

취소를 현재 작업의 종료로 연결하고 싶다면 오류를 무시하지 않고 control flow에 반영할 수 있다.

```swift
do {
    try await Task.sleep(for: .seconds(1))
} catch {
    return
}
```

흐름은 다음과 같다.

```text
Task.sleep
↓
취소 감지
↓
오류 throw
↓
catch
↓
return
↓
download 종료
```

## Important Distinction

```markdown
Task { ... }
- 새로운 Task를 만들고 실행을 시작
- 완료될 때까지 현재 코드를 자동으로 기다리게 하지는 않음

task.cancel()
- Task 강제 종료 X
- 취소 요청

Task.isCancelled
- 현재 Task의 취소 상태 확인

Task.checkCancellation()
- 취소 상태라면 오류를 throw

Task.sleep
- 현재 Task를 suspend 할 수 있음
- cancellation에 반응하며 오류를 던질 수 있음
```

## Takeaway

Task cancellation을 볼 떄 다음과 같이 읽는다.

> cancel() 이 Task를 죽이는 것이 아니라 취소를 요청한다.

그리고 Task 내부에서는 다음을 확인한다.
1. 누가 이 Task에 취소를 요청하는가?
2. Task 는 어느 시점에서 취소를 감지하는가?
3. 취소를 감지한 뒤 실제 실행 종료로 어떻게 연결하는가?
4. 오류를 try? 드응로 무시하고 있지는 않은가?

Cancellation 은 **요청과 실제 종료가 분리되어 있는 협력적인 과정**으로 이해한다.
