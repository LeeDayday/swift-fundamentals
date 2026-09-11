# Generics & Type Constraint

## Question

```swift
func find<T: IdentifiableItem>(
    id: Int,
    in: items: [T]
) -> T?
```

`T` 는 무엇이며, 왜 단순히 `any IdentifiableItem` 을 사용하지 않고, Generic으로 타입을 표현할까?

## My Prediction

`T` 는 하나의 고정된 Swift 타입이 아니라, 함수를 호출할 때 구체적인 타입으로 결정되는 것으로 예상했다.

```swift
let result = find(id: 2, in: users)
```

`users` 의 타입이 `[User]` 이므로 이 호출에서는:

```text
T = User
T? = User?
```

가 될 것이라고 예상했다.

## Principle

### Generic Type Parameter

```swift
func find<T>(...)
```

`T` 는 Generic Type Parameter다.
하나의 고정된 타입을 미리 지정하는 대신, 함수를 사용하는 시점에 구체적인 타입이 결정될 수 있다.

```swift
find(id: 2, in: users)
```

에서는 `[User]` 가 전달되므로 `T` 는 `User` 로 결정된다.

### Generic Constraint

```swift
<T: IdentifiableItem>
```

`T` 가 아무 타입이나 될 수 있다는 뜻은 아니다.
`T` 는 `IdentifiableItem` 을 준수해야 한다는 제약이 존재한다.
따라서 함수 내부에서는 `IdentifiableItem` 이 보장하는 기능을 사용할 수 있다.

```swift
item.id
```

### Generic vs Protocol Existential

Generic을 사용하면 구체적인 타입 관계가 유지된다.

```swift
func find<T: IdentifiableItem>(
    id: Int,
    in items: [T]
) -> T?
```

`[User]` 를 전달하면:

```swift
T = user
return type = User?
```

따라서 호출 결과에서 `User` 가 제공하는 기능을 사용할 수 있다.

```swift
result?.name
```

반면:

```swift
let item: any IdentifiableItem = User(
    id: 1,
    name: "Dani
)
```

`item` 을 통해서는 `IdentifiableItem` 이 보장하는 기능만 사용할 수 있다.

```swift
item.id // 가능
item.name // 불가능
```

실제 값이 `User` 이더라도 `item` 이라는 표현을 `any IdentifiableItem` 로 사용하고 있기 때문이다.

### Connection to Static Type

이전에 학습한 Static Type 과 연결해서 이해할 수 있다.

```swift
let animal: Animal = Dog()

animal.sound() // 가능
animal.fetch() // 불가능
```

실제 객체가 `Dog` 이더라도 `animal` 의 static type을 통해 사용할 수 있다고 보장된 멤버만 접근할 수 있었다.

Protocol existential 에서도 비슷하다.

```swift
let item: any IdentifiableItem = User(...)

item.id // 가능
item.name // 불가능
```

`User` 의 기능이 필요하다면 구체적인 타입으로 다시 확인할 수 있다.

```swift
if let user = item as? User {
    print(user.name)
}
```

## Important Distinction

```markdown
T: IdentifiableItem

- 특정 조건을 만족하는 구체 타입 T
- 호출 시 T 가 구체적으로 결정됨
- 그 타입 관계가 유지됨

any IdentifiableItem

- IdentifiableItem을 준수하는 어떤 값
- 구체 타입에 의존하지 않고 사용
- protocol이 보장하는 인터페이스를 통해 접근
```

## Takeaway

Generic 코드를 볼 때 `<T>` 를 단순히 "아무 타입이나 받는다"고 읽지 않는다.
다음을 확인한다.

1. `T` 에는 어떤 constraint가 있는가?
2. 호출 시 `T` 는 어떤 구체 타입으로 결정되는가?
3. 입력과 반환값 사이에서 `T` 라는 타입 관계가 어떻게 유지되는가?
4. 구체 타입을 유지해야 하는가, 아니면 `any Protocol` 수준으로 다루면 충분한가?

> Generic 은 조건을 만족하는 여러 타입을 받을 수 있으면서도, 호출에서 결정된 구체적인 타입 관계를 유지할 수 있다.