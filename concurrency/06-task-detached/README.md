# Task Context Inheritance & Lifecycle

## Question

`Task {}` 와 `Task.detached {}` 는 모두 새로운 Task를 생성한다.
그런데 왜 `@MainActor` 클래스 내부에서 생성했을 때 다음과 같은 차이가 발생할까?

```swift
Task {
    updateName("Mina")
}

Task.detached {
    await self.updateName("Alex")
}
```

또한 두 Task 는 생성한 함수가 종료되거나 화면이 사라지면 자동으로 취소될까?

## My Prediction

`detached` 는 기존 실행 맥락에서 분리된다는 의미이므로, 현재 Actor Isolation을 상송하지 않을 것이라고 예상했다.

따라서 `Task.detached` 에서는 `updateName()` 이 속한 인스턴스를 명시적으로 참조하고, MainActor에 접근하기 위해 `await` 이 필요하다고 생각했다.

또한 `Task {}` 는 Unstructured Task 이므로, 생성한 함수나 화면의 생명주기와 자동으로 연결되지는 않을 것이라고 예상했다.

## What I Missed

### 1. self 와 await은 서로 다른 역할을 한다.

- `self`: 현재 인스턴스를 명시적으로 참조한다.
- `await`: 비동기 작업의 suspension 가능성을 표시한다. 다른 actor에 격리된 동기 메서드를 호출할 때도 필요할 수 있다.

따라서 `Task.detached` 에서 `await self.updateName()` 을 사용하는 이유를 단순히 실행 맥락이 분리되었기 때문이라고만 이해해서는 안 된다.

`self` 의 명시적 사용은 클로저 캡처 규칙과 관련이 있고, `await` 은 Actor Isolation과 관련이 있다.

### 2. Actor Isolation이 같아도 Task의 특성이 완전히 같아지는 것은 아니다.

```swift
Task {
    updateName("Mina")
}

Task.detached { @MainActor in
    self.updateName("Alex")
}
```

두 Task 모두 MainActor에 격리되어 실행되지만, 실행 맥락을 상속하는 방식은 다르다.
`Task {}` 는 모두 현재 Actor Isolation, Task Priority, Task-local values 등을 상속한다.
반면 `Task.detached {}` 는 이러한 맥락을 상속하지 않는다. 단, 클로저에 `@MainActor` 를 명시하면 해당 클로저를 MainActor에 격리할 수 있다.

### 3. Task를 생성하는 것과 완료를 기다리는 것은 다르다.

```swift
func startWork() {
    Task {
        try? await Task.sleep(for: .seconds(5))
        print("Finished")
    }
}
```

`startWork()` 가 종료되어도 생성한 Task는 계속 실행될 수 있다.

또한 `Task {}` 가 반환하는 핸들을 저장하지 않았다면 나중에 해당 Task를 직접 취소하기 어렵다.

## Principle

### Task Context Inheritance

| 구분 | Task {} | Task.detached {} |
| -- | -- | -- |
| 새로운 Task  생성 | O | O |
| 현재 Actor Isolation 상속 | O | X |
| Task Priority 상속 | O | X |
| Task-local values 상속 | O | X |
| Structured Child Task | X | X |

`Task.detached { @MainActor in }` 처럼 클로저의 Acotr Isolation 을 명시적으로 지정할 수 있다.

### Structured vs Unstructured Task

`async let` 은 Structured Child Task 를 생성한다.
부모 Task와 구조화된 생명주기를 공유하며, 부모는 자식 작업이 완료되기 전에 해당 범위를 벗어날 수 없다.
반면 `Task {}` 와 `Task.detached {}` 는 Unstructured Task 다.
생성한 함수가 반환되었다고 자동으로 취소되거나 완료되는 것은 아니다.

### Task Cancellation

```swift
var workTask: Task<Void, Never>?

func startWork() {
    workTask = Task {
        try? await Task.sleep(for: .seconds(5))
        print("Finished")
    }
}

func stopWork() {
    workTask?.cancel()
}
```

`cancel()` 은 작업을 강제로 종료하지 않고 취소를 요청한다.
따라서 `try?` 로 취소 오류를 무시하면 이후 코드가 계속 실행될 수 있다.

### SwiftUI `.task {}``

```swift
struct ProfileView: View {
    var body: some View {
        Text("Profile")
            .task {
                await loadData()
            }
    }
}
```

SwiftUI의 `.task {}` 는 View Modifier 다.
View 가 나타날 때 작업을 시작하고, View 가 사라지면 SwiftUI 가 해당 Task에 취소를 요청한다. 일반적인 `Task {}` 와 달리 SwiftUI가 작업의 생명주기를 관리한다.

## Important Distinction

- Task 생성: 비동기 작업을 시작하도록 한다.
- Actor Isolation: 작업이 어떤 격리 영역에서 실행되어야 하는지 결정한다.
- Task Context Inheritance: 새 Task 가 기존 실행 맥락의 어떤 특성을 상속하는지 결정한다.
- Task Lifecycle: 작업의 완료와 취소를 누가 책임지는지에 관한 문제다.
- Task Cancellation: 취소 요청과 실제 작업 종료는 다르다.

## Design Takeaway

Task를 생성할 때는 다음을 고려한다.

1. 현재 Actor Isolation을 상속해야 하는가?
2. 기존 Task의 우선순위와 Task-local values를 상속해야 하는가?
3. 생성한 Task의 완료를 기다려야 하는가?
4. 누가 Task의 생명주기와 취소를 관리해야 하는가?

> 새로운 Task를 생성하는 방식은 실행 맥락뿐 아니라 작업의 생명주기와 책임 범위에도 영한을 준다.
