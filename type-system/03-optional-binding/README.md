# Optional & Optional Binding

## Question

```swift
let user = findUser(id: 1)

print(type(of: user))

if let user {
    print(type(of: user))
    print(user.name)
}

print(type(of: user))
```

`if let` 전후에서 `user` 의 타입은 어떻게 달라질까?

그리고 `User?` 는 타입 시스템에서 무엇을 의미할까?

## My Prediction

`findUser()` 의 반환 타입은 `User?` 이므로 처음 `user` 의 타입은 `User?` 일 것으로 예상했다.

`if let user` 가 성공하면 Optional 이 안전하게 unwrap 되므로 내부의 `user` 는 `User` 가 될 것으로 예상했다.

처음에는 한 번 unwrap 되면 바깥의 `user` 도 이후에는 `User` 가 될 것이라고 생각했다.

## What I Missed

if let 은 기존 변수의 타입을 변경하지 않는다.

```swift
let user: User? = findUser(id: 1)

if let user {
    // user: User
}

// user: User?
```

if let 이 성공하면 해당 scope 안에서 unwrap 된 값을 새로운 상수로 사용할 수 있게 된다.

따라서 같은 이름을 사용하더라도 안쪽 user와 바깥 user 는 구분된다.

```text
바깥 scope
user: User?
    │
    │ if let 성공
    ↓
안쪽 scope
user: User

    ↓ scope 종료

바깥 scope
user: User?
```

## Optional<T>

`User?` 는 `User` 에 단순히 특별한 표시가 붙은 것이 아니라 `Optional<User>` 라는 타입의 축약 표현이다.

```swift
User? == Optional<User>
```

`Optional` 을 단순화해서 보면 다음과 같이 이해할 수 있다.

```swift
enum Optional<Wrapped> {
    case none
    case some(Wrapped)
}
```

따라서 `Optional<User>` 는 두 가지 상태를 가질 수 있다.

```text
Optional<User>
├── .none
└── .some(User)
```

예를 들어 

```swift
let a: User? = nil
let b: User? = User(name: "Dani")
```

두 변수의 타입은 모두 `Optional<User>`다.

차이는 현재 가지고 있는 case 다.

```text
a
→ Optional<User>
→ .none

b
→ Optional<User>
→ .some(User)
```

## Optional Binding

```swift
if let user = optionalUser {
    print(user.name)
}
```

`if let` 은 `Optional<User>` 에 값이 존재하는지 확인한다.

`.some(User)` 라면 내부의 `User` 를 꺼내 `if` scope 안에서 `User` 타입의 상수로 사용할 수 있다.

```text
optionalUser: Optional<User>
        ↓
      .none
        → if 내부 실행 X

      .some(User)
        ↓
   내부 User를 꺼냄
        ↓
   user: User
        ↓
   if 내부 실행
```

## Binding

여기서 binding은 SwiftUI의 `@Binding` 을 의미하지 않는다.

일반적인 프로그래밍 용어로, 값을 특정 이름을 통해 사용할 수 있도록 연결하는 것을 의미한다.

```swift
let name = "Dani"
```

에서는 `"Dani"` 라는 값을 `name` 이라는 이름으로 사용할 수 있다.

Optional Binding 에서도 같은 의미다.

```swift
if let user = optionalUser
```

Optional 내부의 값을 꺼내 `user` 라는 새로운 상수로 사용할 수 있게 한다.

## Important Distinction

```markdown
User
- User 값 자체를 나타내는 타입

User?
- Optional<User>
- .none 또는 .some(User)

if let
- Optional 에 값이 있는지 확인
- 값이 있다면 내부 값을 unwrap
- 해당 scope에서 새로운 상수로 사용

if let 이 끝난 뒤
- 기존 Optional 변수의 타입은 그대로
```

## Takeaway

Optional 코드를 볼 때 `?` 를 단순히 "nil 일 수도 있겠다"는 표시로만 읽지 않는다.

```swift
let user: User?
```

를 보면:

```
user: Optional<User>
```

라는 별도의 타입으로 생각한다.

그리고 if let 을 보면:
> Optional 자체를 User로 바꾸는 것이 아니라,
> 값이 존재하는 경우 내부의 User 를 꺼내
> 현재 scope 에서 사용할 수 있게 한다.

라고 이해한다.
