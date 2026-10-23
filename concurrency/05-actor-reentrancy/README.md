# Actor Reentrancy

## Question

```swift
actor Inventory {
    private var stock = 1

    func purchase() async -> Bool {
        guard stock > 0 else {
            return false
        }
        try? await Task.sleep(for: .seconds(1))

        stock -= 1
        return true
    }
}
```

초기 재고가 1개인 상태에서 두 Task 가 동시에 purchase() 를 호출한다.

Actor Isolation 이 적용되어 있는데도 두 구매가 모두 성공할 가능성이 있을까?

## My Prediction

두 Task 가 `async let`으로 생성되면 동시에 진행될 수 있다.

첫 번째 Task 가 `guard` 를 통과한 후 `await` 에서 suspend 되면, 두 번째 Task 도 같은 actor 에 들어와 `stock = 1` 을 확인할 수 있다.

따라서 두 작업 모두 구매에 성공하고, 최종 재고가 -1이 될 수 있다고 예상했다.

## What I Missed

처음에는 Actor Isolation 이 공유 상태에 대한 접근을 관리하므로, actor 내부 메서드의 실행 전체가 보호된다고 생각하기 쉬웠다.

하지만 Actor Isolation이 보장하는 것은 같은 actor에 격리된 코드의 충돌하는 동시 실행을 방지하는 것이다.

`await`으로 Task 가 suspend 되면 다른 Task 가 같은 actor의 격리된 코드를 실행할 수 있다.

따라서 `await` 이전에 확인한 상태가 이후에도 유지된다는 보장은 없다.

## Principle

### Actor Isolation

Actor 는 공유되는 가변 상태를 격리하여 여러 Task 가 안전하게 접근할 수 있도록 한다.

```swift
actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }
}
```

`increment()` 내부에는 suspension point 가 없다.

따라서 한 Task 가 이 메서드를 실행하는 동안 다른 Task 가 같은 actor 의 격리된 상태를 변경할 수 없다.

두 Task 가 각각 1000번씩 `increment()` 를 호출하고 모든 호출이 완료되었다면 최종값은 2000이다.

다만 두 Task 의 호출 순서는 보장되지 않는다.

### Actor Reentrancy

```swift
func purchase() async -> Bool {
    guard stock > 0 else {
        return false
    }

    try? await Task.sleep(for: .seconds(1))

    stock -= 1
    return true
}
```

`await` 에서 현재 Task 가 suspend 되면 다른 Task 가 같은 actor 에 들어와 실행될 수 있다.

```text
Task A                     Task B
   │                          │
stock = 1 확인
   │
guard 통과
   │
await → suspend
                              stock = 1 확인
                                 │
                              guard 통과
                                 │
                              await → suspend
   │
resume
   │
stock = 0
                                 │
                              resume
                                 │
                              stock = -1
```

이것이 Actor Reentrancy 로 발생할 수 있는 문제다.

Actor Isolation이 깨진 것은 아니다.

각 Task 가 actor-isolated 상태에 접근하는 순간은 보호되지만, `await` 이전과 이후의 실행 구간 전체가 하나의 원자적 작업으로 보장되지는 않는다.

## Experiment

`Task.sleep` 의 위치만 변경한다.

### Before

```swift
guard stock > 0 else {
    return false
}

try? await Task.sleep(for: .seconds(1))

stock -= 1
```

조건 검사와 상태 변경 사이에 suspension point 가 존재한다.

### After

```swift
try? await Task.sleep(for: .seconds(1))

guard stock > 0 else {
    return false
}

stock -= 1
```

이제 조건 검사와 상태 변경 사이에 suspension point 가 없다.

따라서 두 Task 가 같은 actor 에 접근하더라도, 하나의 Task 가 재고를 검사하고 변경하는 도중 다른 Task 가 개입할 수 없다.

가능한 결과는 다음과 같다.

```text
first = true, second = false
또는
first = false, second = true

remainingStock = 0
```

## Actor vs Class

Actor Isolation과 suspension point의 역할을 구분해야 한다.

일반적인 class에서는:

```swift
final class Counter {
    var value = 0

    func increment() {
        value += 1
    }
}
````

메서드 내부에 `await`이 없어도 여러 Thread가 동시에 `increment()`를 실행할 수 있다.

따라서 `await` 이 없다는 사실만으로 공유 상태에 대한 접근이 안전해지는 것은 아니다.

반면 actor에서는 같은 actor에 격리된 코드의 충돌하는 동시 실행이 제한된다.

```text
일반 Class
→ suspension point가 없어도 동시 접근 가능

Actor
→ 격리된 상태에 대한 접근 조정
→ suspension point가 없는 동기 실행 구간은
  다른 Task가 중간에 개입할 수 없음
```


## Important Distinction

```text
Actor Isolation
→ 공유되는 가변 상태를 격리
→ Data Race 방지

Actor Reentrancy
→ await에서 Task가 suspend되는 동안
  다른 Task가 같은 actor에 진입 가능

Suspension Point
→ 현재 Task의 실행이 일시 중단될 수 있는 지점

Logical Race Condition
→ Data Race가 없더라도
  작업의 실행 순서에 따라 잘못된 결과 발생 가능
```

## Design Takeaway

Actor를 사용한다고 해서 모든 비즈니스 로직의 일관성이 자동으로 보장되는 것은 아니다.

특히 actor 내부에서 `await` 을 발견하면 다음을 확인한다.

1. `await` 이전에 어떤 상태를 읽거나 검사했는가?

2. Task가 suspend된 동안 다른 Task가 그 상태를 변경할 수 있는가?

3. Task가 재개된 이후에도 이전 상태가 유효한가?

4. 상태 검사와 변경을 하나의 연속된 actor-isolated 실행 구간으로 구성할 수 있는가?

한 줄로 정리하면:

> Actor Isolation은 Data Race를 방지하지만, await을 사이에 둔 상태의 일관성까지 자동으로 보장하지는 않는다.