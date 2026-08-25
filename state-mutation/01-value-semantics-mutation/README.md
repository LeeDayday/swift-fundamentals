# Value Semantics & Mutation

## Question

```swift
struct Counter {
    var value: Int

    mutating func increment() {
        value += 1
    }
}

final class Dashboard {
    var counter: Counter

    init(counter: Counter) {
        self.counter = counter
    }

    func increase() {
        counter.increment()
    }
}

var original = Counter(value: 0)
let dashboard = Dashboard(counter: original)

dashboard.increase()
original.increment()

print(original.value)
print(dashboard.counter.value)
```

`original`을 `Dashboard`에 전달한 뒤 `original`과 `dashboard.counter`는 같은 상태를 공유할까?

그리고 struct의 메서드에서 값을 변경할 때는 왜 `mutating`이 필요할까?

---

## My Prediction

`Counter`는 struct이므로 value type이다.

따라서 `original`을 `Dashboard`에 전달하면 `original`과 `dashboard.counter`는 서로 독립적인 값을 가지게 될 것이라고 예상했다.

```text
original.increment()          → original.value == 1
dashboard.increase()          → dashboard.counter.value == 1
```

최종 출력:

```text
1
1
```

---

## What I Missed

처음에는 value type이라는 것을 **기본적으로 불변인 타입**이라고 생각했다.

하지만 다음 두 개념은 별개다.

* Value Semantics: 값을 전달했을 때 어떤 관계를 가지는가?
* Mutability: 현재 값을 변경할 수 있는가?

struct도 `var`로 선언되어 있다면 값을 변경할 수 있다.

```swift
var counter = Counter(value: 0)
counter.increment()
```

반면 `let`으로 선언된 struct 값은 변경할 수 없다.

```swift
let counter = Counter(value: 0)
counter.increment() // Compile Error
```

---

## Principle

### Value Semantics

struct는 value type이다.

값을 다른 변수나 프로퍼티에 전달하면 각각 독립적인 값을 가지게 된다.

```swift
var original = Counter(value: 0)
var copied = original

original.increment()
```

`original`의 변경이 `copied`의 상태를 함께 변경시키지 않는다.

---

### mutating

struct의 instance method가 `self` 또는 저장 프로퍼티를 변경하려면 `mutating`으로 선언해야 한다.

```swift
struct Counter {
    var value: Int

    mutating func increment() {
        value += 1
    }
}
```

`value`를 변경하는 것은 `Counter`라는 값의 상태를 변경하는 것이다.

`mutating`은 해당 메서드가 `self`의 상태를 변경할 수 있음을 나타낸다.

---

## Value Type vs Reference Type

Value type과 reference type에서는 `let`의 의미가 다르게 나타난다.

### Value Type

```swift
let counter = StructCounter()
counter.increment() // Compile Error
```

`counter`라는 값 자체가 불변이므로 저장 프로퍼티를 변경할 수 없다.

### Reference Type

```swift
let counter = ClassCounter()

counter.increment()    // OK
counter.value = 10     // OK
```

`let`은 `counter`가 가리키는 인스턴스를 다른 인스턴스로 변경할 수 없다는 의미다.

따라서:

```swift
counter = ClassCounter() // Compile Error
```

는 불가능하지만, 같은 인스턴스 내부의 상태는 변경할 수 있다.

---

## Important Distinction

```text
Value Semantics
→ 값을 전달하면 독립적인 값을 가진다.

Reference Semantics
→ 여러 변수가 동일한 인스턴스를 참조할 수 있다.

let + value type
→ 값 자체를 변경할 수 없다.

let + reference type
→ 다른 인스턴스를 참조하도록 변경할 수 없다.
→ 참조하는 인스턴스의 내부 상태는 변경될 수 있다.
```

---

## Experiment

다음 두 타입을 `let`으로 선언한다.

```swift
struct StructCounter {
    var value = 0

    mutating func increment() {
        value += 1
    }
}

final class ClassCounter {
    var value = 0

    func increment() {
        value += 1
    }
}

let a = StructCounter()
let b = ClassCounter()

a.increment() // Compile Error
b.increment() // OK
```

두 변수 모두 `let`이지만 결과가 다르다.

`a`의 상태를 변경하는 것은 value type인 `a` 자체를 변경하는 것이다.

반면 `b.increment()`는 `b`가 다른 인스턴스를 참조하도록 변경하는 것이 아니라, 현재 참조하고 있는 인스턴스의 상태를 변경한다.

---

## Design Takeaway

코드를 읽을 때 `var` / `let`만 보는 것이 아니라 먼저 해당 타입이 value semantics인지 reference semantics인지 확인한다.

특히 상태 변경 코드를 볼 때 다음을 구분한다.

1. 값 자체를 변경하는가?
2. 다른 인스턴스를 참조하도록 변경하는가?
3. 현재 참조하고 있는 인스턴스의 내부 상태를 변경하는가?

struct의 `mutating`은 단순히 프로퍼티 변경을 허용하는 문법으로 외우기보다, **value type의 `self`를 변경하는 메서드임을 표현하는 것**으로 이해한다.
