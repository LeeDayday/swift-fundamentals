# Static Type & Dynamic Type

## Question

```swift
let dog = Dog()
let animal: Animal = dog

describe(dog)
describe(animal)

dog.sound()
animal.sound()
```

dog와 animal은 같은 `Dog` 인스턴스를 가리킨다.

animal에 대하여 describe 함수 호출 결과와 sound 메소드 호출 결과는 다르다.

왜 함수 호출 결과가 서로 다르게 결정될 수 있을까?

---

## My prediction

처음에는 다음과 같이 예상했다.

```text
describe(dog) -> Dog
describe(animal) -> Animal

dog.sound() -> Woof
animal.sound() -> Animal sound
```

`animal`의 타입이 `Animal`이므로, `Animal.sound()`가 실행될 것이라고 생각했다.

## What I Missed

메소드 호출에는 서로 다른 두 문제가 있었다.

> 코드를 해석할 때 서로 다른 두 판단을 구분하지 못했다.
> 1. 이 메서드에 접근할 수 있는가?
> 2. 접근할 수 있다면 override된 구현 중 어느 구현이 실행되는가?
> 처음에는 두 판단 모두 변수의 타입만으로 결정한다고 생각했다.

## Principle

### Static Type
- 컴파일러가 표현식을 볼 때 알고 있는 타입

```swift
let animal: Animal = Dog()
```

`animal`의 static type은 `Animal`

Static type은 다음과 같은 판단에 사용된다.

- 어떤 프로퍼티나 메서드에 접근할 수 있는가
- overload된 함수 중 어떤 함수를 호출할 것인가

### Dynamic Type
- runtime에서 실제 인스턴스가 가지는 타입

위 코드에서 `animal`의 dynamic type은 `Dog`

override된 instance method의 실제 구현은 dynamic type을 기준으로 runtime에 선택된다.

## The Important Distinction

```swift
let animal: Animal = Dog()
``` 

### Overload

```swift
describe(animal)
```

animal의 static type이 Animal이므로

```swift
describe(_ animal: Animal)
```
이 compile time에 선택된다.

### Override

```swift
animal.sound()
```

Animal에 sound()가 존재하므로 호출 자체는 허용된다.
하지만 실제 객체는 Dog 이므로 runtime에는

```swift
Dog.sound()
```

가 실행된다.

---

## Static Type과 메서드 접근

```swift
animal.fetch()
```

는 불가능하다.

실제 객체가 `Dog`이더라도 `animal`의 static type인 `Animal`에는 `fetch()`가 없기 때문이다.

즉:
> 호출 가능 여부는 static type,
> override 된 구현 선택은 dynamic type

---

## Downcasting

```swift
if let dog = animal as? Dog {
    dog.fetch()
}
```

runtime에 실제 타입이 `Dog`인지 확인하고, 성공하면 `dog`를 static type `Dog`로 사용할 수 있다.

- `as?`
    - 실패시 nil 반환
- `as!`
    - 실패시 runtime trap 발생
    
--

## Experiment

### Static type 변경

```swift
let animal: Dog = dog
```

예상:
```text
describe(animal) -> Dog
animal.sound() -> Woof
```

- `describe`의 결과가 바뀌는 이유는 static type이 Animal -> Dog로 바뀌었기 때문

### Design Takeaway

overload는 호출하는 표현식의 static type에 따라 함수가 선택된다.  따라서 실제 runtime 타입에 따라 행동을 달리하고 싶다면

```swift
func describe(_ animal: Animal)
func describe(_ dog: Dog)
```

처럼 overload에 의존하는 것보다,

```swift
class Animal {
    func describe() {}
}

class Dog: Animal {
    override func describe() {}
}
```

처럼 override를 통한 dynamic dispatch가 의도에 더 적합할 수 있다.

---

## 핵심 요약

### Static Type
- compile time에 표현식에 대해 알려진 타입
- 접근 가능한 프로퍼티/메서드와 overload resolution에 영향

### Dynamic Type
- runtime에 실제 인스턴스가 가지는 타입
- override된 메서드의 실제 구현 선택에 영향

**같은 animal을 사용하더라도 함수/메서드 선택 방식이 같지 않다.**
