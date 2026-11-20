# Task & Object Lifetime

## Question

다음 코드에서 run() 이 종료되면 Worker 인스턴스의 `deinit이 즉시 호출될까?

```swift 
final class Worker {
    let name = "A"
    var task: Task<Void, Never>?

    func start() {
        task = Task {
            print("start: \(name)")
            try? await Task.sleep(for: .seconds(2))
            print("finish: \(name)")
        }
    }    

    deinit {
        print("deinit")
        task?.cancel()
    }
}
```

deinit에서 Task 를 취소하도록 설계했는데, 이 방식이 의도대로 동작할까?

## My Prediction

`deinit`은 인스턴스에 대한 마지막 강한 참조가 사라질 때 호출된다.

Task 클로저에서 `name` 에 접근하는 과정에 `self` 가 캡처되므로, `run()` 의 지역 변수 `worker` 가 범위를 벗어나더라도 Task 가 `Worker` 를 유지할 수 있다고 예상했다.

따라서 Task 가 완료되기 전에는 `deinit` 이 호출되지 않을 수 있다.

또한 `deinit` 에서 Task 를 취소하려는 설계는, Task가 객체를 유지하고 있다면 취소 자체가 지연되는 문제가 있다고 판단했다.

## Experiment 1: Strong Capture

```swift
Task {
    print("start: \(name)")
    try? await Task.sleep(for: .seconds(2))
    print("finish: \(name)")
}
```

클로저에서 인스턴스 프로퍼티 name 에 접근하기 위해 self 를 강하게 캡쳐한다.

Task 가 실행되는 동안 Worker 의 생명주기가 연장될 수 있다.

Task 가 정상적으로 완료되면 실행 클로저가 유지하던 강한 참조가 해제될 수 있으므로, 반드시 영구적인 Retain Cycle이 발생하는 것은 아니다.

## Experiment 2: Weak Capture + Strong Binding

```swift
Task { [weak self] in
    guard let self else { return }

    print("start: \(name)")
    try? await Task.sleep(for: .seconds(2))
    print("finish: \(name)")
}
```

처음에는 `[weak self]` 를 사용하면 `Worker` 가 즉시 해제될 수 있다고 생각했다.

하지만 `guard let self` 가 성공하면 새로운 강한 지역 참조가 생성된다.

이 강한 참조가 `await` 을 넘어 유지되면 Task suspend 된 동안에도 `Worker` 의 생명주기가 연장될 수 있다.

따라서 실행 순서에 따라 두 가지 상황이 가능하다.

- Task 가 먼저 실행되어 `guard` 에 성공하면, `Worker` 의 해제가 지연될 수 있다.
- `Worker` 가 먼저 해제되면, Task 의 `guard` 가 실패하여 종료된다.

약한 참조로 캡처하는 것과 강한 참조로 바인딩하는 것은 별개의 동작이다.

## Experiment 3: Weak Capture + Value Extraction

```swift
Task { [weak self] in 
    guard let name = self?.name else { return }

    print("start: \(name)")
    try? await Task.sleep(for: .seconds(2))
    print("finish: \(name)")
}
```

이 경우에는 `self` 자체를 강한 지역 상수로 유지하지 않는다.

`self?.name` 을 통해 `String` 값을 읽고, 이를 새로운 지역 상수 `name`에 저장한다.

`String` 은 값 타입이므로 name 을 유지하기 위해 `Worker` 를 계속 참조할 필요가 없다.

따라서 Task 가 `sleep` 중이더라도 `Worker` 의 마지막 강한 참조가 사라지면 `deinit` 이 호출될 수 있다.

여기서 name 은 새로운 프러퍼티가 아니라 클로저 내부의 지역 상수다.

## Principle

### ARC와 객체의 생명 주기

Swift의 ARC는 클래스 인스턴스에 대한 강한 참조를 관리한다.

마지막 강한 참조가 사라지면 객체가 해제되며, 해제 과정에서 `deinit` 이 호출된다.

`weak` 참조는 강한 참조 카운트를 증가시키지 않으며, 참조 대상이 해제되면 자동으로 `nil` 이 된다.

### Closure Capture 와 Strong Binding

```swift
Task { [weak self] in 
    guard let self else { return }
}
```

- [weak self]: 클로저가 인스턴스를 약하게 캡처한다.
- guard let self: 인스턴스가 살아 있다면 강한 지역 참조를 생성한다.

따라서 [weak self] 를 사용했다는 사실만으로 Task 가 객체의 생명주기를 연장하지 않는다고 판단해서는 안 된다.

### Suspension 과 참조 유지

await 은 현재 Task 가 suspend 될 수 있는 지점이다.

Task 가 suspend 되는 동안에도 이후 실행에 필요한 지역 값과 참조는 유지될 수 있다.

따라서 await 이전에 생성한 강한 참조가 이후에도 필요하다면 객체의 해제가 지연될 수 있다.

## Important Distinction

| 코드 | Task 가 유지하는 대상 | 객체 생명주기에 미치는 영향 |
| -- | -- | -- |
| Task { print(name) } | 강하게 캡쳐한 self | 해제 지연 가능 |
| [weak self] + guard let self | 강한 지역 참조 self | 해제 지연 가능 |
| [weak self] + guard let name = self?.name | String 값 name | 장기간 강한 참조 불필요 |

## Design Takeaway

Task 내부에서 객체의 프로퍼티에 접근할 때는 다음을 확인한다.

1. 클로저가 self를 강하게 캡쳐하는가?
2. [weak self] 이후 강한 지역 참조를 생성하는가?
3. 해당 강한 참조가 await 을 넘어 유지되는가?
4. Task 가 완료되지 않는다면 객체의 해제도 지연될 수 있는가?
5. deinit에서 Task 를 취소하는 설계가 실제로 동작할 수 있는가?

특히 Task 가 객체를 강하게 유지하고 있다면, 객체가 해제될 때 Task를 취소하는 방식은 의도대로 동작하지 않을 수 있다.

> [weak self] 의 사용 여부보다 Task 가 어떤 강한 참조를 얼마나 오래 유지하는지가 객체의 생명주기를 결정한다.
