# Property Observers

## Question

```swift
struct Temperature {
    var celsius: Int {
        willSet {
            print("willSet: \(celsius) -> \(newValue)")
        }

        didSet {
            print("didSet: \(oldValue) -> \(celsius)")
        }
    }
}

var temparature = Temperature(celsius: 20)

print("A")
temperature.celsius = 30
print("B")
```

`willSet` 과 `didSet` 은 프로퍼티의 값이 변경되는 과정에서 각각 언제 실행될까?

그리고 `newValue`, `oldValue` 는 어떤 값을 나타낼까?

## My Prediction

`willSet` 은 값이 실제로 변경되기 전에, `didSet` 은 값이 변경된 후 실행될 것으로 예상했다.

따라서 출력은 다음과 같을 것으로 예상했다.

```text
A
willSet: 20 -> 30
didSet: 20 -> 30
B
```

## Principle

### willSet

프로퍼티의 값이 실제로 변경되기 직전에 실행된다.

```swift
willSet {
    print(celsius)
    print(newValue)
}
```

`celsius` 는 아직 변경 전의 값이고,
`newValue` 는 새롭게 저장될 값이다.

### didSet

프로퍼티의 값이 변경된 직후 실행된다.

```swift
didSet {
    print(oldValue)
    print(celsius)
}
```

`oldValue` 는 변경 전의 값이고,
`celsius` 는 이미 변경된 현재 값이다.


## State Change Flow

```markdown
현재 값 = 20
    ↓
willSet
    ├─ 현재 값: 20
    └─ newValue: 30
    ↓
실제 값 변경
20 → 30
    ↓
didSet
    ├─ oldValue: 20
    └─ 현재 값: 30
```

## Mutation inside didSet

`didSet` 에서는 변경된 값을 확인한 뒤 프로퍼티의 값을 다시 보정할 수 있다.

```swift
struct Score {
    var value: Int {
        didSet {
            if value < 0 {
                value = 0
            }
        }
    }
}

var score = Score(value: 10)
score.value = -5
```

실행 흐름은: 

```markdown
10
↓
-5로 변경
↓
didSet 실행
↓
value < 0
↓
value = 0
```

최종 값은 0이다.

`didSet` 내부에서 해당 프로퍼티에 다시 값을 할당해도, 그 할당 자체가 `didSet` 을 다시 호출하여 무한 반복되지는 않는다.

## Important Distinction

```text
willSet
- 변경 직전
- 현재 값은 아직 이전 값
- newValue로 새 값 확인

didSet
- 변경 직후
- 현재 값은 이미 새로운 값
- oldValue로 이전 값 확인
```

## Takeaway

Property Observer를 볼 때는 상태 변경을 다음 세 단계로 나누어 읽는다.
1. 변경 전 - `willSet`
2. 실제 값 변경
3. 변경 후 - `didSet`

`willSet` 은 앞으로 저장될 값을 관찰하고,
`didSet` 은 이미 변경된 상태와 이전 상태를 비교하거나 후속 작업을 수행할 때 사용할 수 있다.
