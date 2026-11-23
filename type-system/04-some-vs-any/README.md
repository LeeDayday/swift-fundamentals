# Opaque Type vs Existential Type

## Question

Swift에서 `some Animal` 과 `any Animal` 은 어떤 차이가 있을까?

```swift
func makeAnimalA(_ isDog: Bool) -> any Animal {
    if isDog {
        return Dog()
    } else {
        return Cat()
    }
}

func makeAnimalB() -> some Animal {
    Dog()
}
```

두 함수 모두 `Animal` 프로토콜을 반환 타입에 사용하지만, 실제 구체 타입을 취급하는 방식은 다르다.

왜 `some Animal` 에서는 조건에 따라 `Dog` 와 `Cat` 을 반환할 수 없을까?

## My Prediction

`Dog` 와 `Cat` 은 모두 Animal 프로토콜을 채틱하지만 서로 다른 구조체다.

`any` 를 사용하면 두 타입을 모두 반환할 수 있지만, `some` 을 사용하면 하나의 구체 타입으로 고정되어야 할 것이라고 예상했다.

또한 `some Animal` 의 정적 타입은 단순히 `Animal` 일 것이라고 예상했다.

## What I Missed

### 1. some 은 구체 타입을 모른다는 의미가 아니다.

```swift
func makeAnimal() -> some Animal {
    Dog()
}
```

컴파일러는 실제 반환 타입이 `Dog` 라는 것을 알고 있다.

하지만 호출자에게는 `Dog` 라는 구체 타입을 공개하지 않고, `Animal` 프로토콜을 준수한다는 계약만 제공한다.

따라서 `some Animal` 은 단순한 `Animal` 타입이 아니라, **구체 타입이 숨겨진 불투명 타입(Opaque Type)** 이다.

### 2. 컴파일러가 아는 정보와 호출자가 사용할 수 있는 기능은 다르다.

```swift
let animal = makeAnimal()

animal.speak() // 가능
animal.fetch() // 컴파일 오류
```

실제 타입이 `Dog` 이더라도 호출자는 `Animal` 프로토콜에 정의된 기능만 사용할 수 있다.

반면 함수가 `Dog` 를 직접 반환한다면 `Dog` 고유의 `fetch()` 에도 접근할 수 있다.

### 3. 실제 구체 타입이 같아도 불투명 타입의 정체성은 다를 수 있다.

```swift
func makeDogA() -> some Animal {
    Dog()
}

func makeDogB() -> some Animal {
    Dog()
}
```

두 함수 모두 Dog 를 반환하지만, 각각의 불투명 반환 타입은 별개의 타입 정체성을 갖는다.

따라서 호출자가 두 반환값을 동일한 타입이라고 가정할 수 없다.

## Principle

### Opaque Type - `some`

some Animal 은 하나의 고정된 구체 타입을 숨긴 채 반환한다.

- 구체 타입은 컴파일 시점에 결정된다.
- 호출자에게는 프로토콜이 보장하는 인터페이스가 공개된다.
- 하나의 불투명 반환 타입 선언은 일관된 구체 타입을 사용해야 한다.
- 서로 다른 불튜명 반환 타입 선언은 별개의 타입 정체성을 갖는다.

### Existential Type - `any`

`any Animal` 은 `Animal` 프로토콜을 준수하는 값을 담을 수 있는 존재 타입이다.

```swift
let animals: [any Animal] = [
    Dog(),
    Cat()
]
```

- 서로 다른 구체 타입의 값을 동일한 존재 타입으로 다룰 수 있다.
- 저장된 값의 실체 구체 타입은 런타임에 달라질 수 있다.
- 호출자는 기본적으로 프로토콜이 보장하는 인터페이스를 사용한다.

## Important Distinction

| 구분 | `Dog` | `some Animal` | `any Animal` |
| -- | -- | -- | -- |
| 구체 타입 공개 | O | X | X |
| 구체 타입 고정 | O | O | X |
| Dog 전용 메서드 접근 | O | X | X |
| 서로 다른 구현체 저장 | X | X | O |

`some` 은 구체 타입을 숨기면서 타입 정체성을 유지한다.

`any` 는 서로 다른 구체 타입을 하나의 존재 타입으로 다룰 수 있게 한다.

## Compiler vs Caller

- Compiler: 코드를 분석하고 타입을 검사하는 도구
- Caller: 함수를 호출하여 사용하는 코드

컴파일러는 `some Animal` 의 실제 구체 타입을 알지만, 호출자는 공개된 인터페이스를 기준으로 코드를 작성해야 한다.

## Experiment

### 서로 다른 불투명 타입

```swift
let a = makeDogA()
let b = makeDogB()

// let animals = [a, b] // 컴파일 오류
```

### 동일한 불투명 타입

```swift
let animals = [
    makeDogA(),
    makeDogA()
]
```

동일한 함수의 반환값이므로 같은 불투명 타입으로 취급할 수 있다.

### 존재 타입으로 묶기

```swift
let animals: [any Animal] = [
    makeDogA(),
    makeDogB(),
    Cat()
]
```

`any Animal` 을 사용하면 서로 다른 불투명 타입과 구체 타입을 하나의 배열에 담을 수 있다.

## Design Takeaway

반환 타입을 결정할 때 다음을 고려한다.

1. 호출자가 구체 타입의 기능까지 알아야 하는가?
2. 구현을 숨기되 하나의 구체 타입을 유지해야 하는가?
3. 서로 다른 구체 타입의 값을 동일하게 다뤄야 하는가?

- Dog: 구체 타입과 기능을 공개하고 싶을 때
- some Animal: 구현을 숨기면서 고정된 타입 정체성을 유지하고 싶을 때
- any Animal: 서로 다른 구현체를 하나의 타입으로 다루고 싶을 때

> `some` 은 구체 타입을 숨기면서 타입 정체성을 유지하고, `any` 는 서로 다른 구체 타입을 하나의 존재 타입으로 다룰 수 있게 한다.
