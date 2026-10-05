# Result

## Question

```swift
func login(password: String) -> Result<User, LoginError> {
    guard password == "swift" else {
        return .failure(.invalidPassword)
    }

    return .success(User(name: "Dani"))
}
```

이전에 배운 `throws` 도 성공과 실패를 표현할 수 있었다.

그렇다면 왜 `Result` 라는 타입이 별도로 필요할까?

`throw` 와 `.failure` 는 실행 흐름에 어떤 차이를 만들까?

## My Prediction

처음에는 `.failure` 가 반환되면 `throw` 처럼 실행 흐름이 준단될 수도 있다고 생각했다.

하지만 `Result` 에서는 실패도 하나의 값으로 반환된다.

```swift
let result = login(password: "wrong")
```

따라서 `result` 에는 실패 결과가 저장되고 다음 코드도 정상적으로 실행될 수 있다.

## Result

`Result` 는 작업의 성공과 실패를 값으로 표현한다.

```swift
Result<User, LoginError>
```

는 두 가지 상태를 가질 수 있다.

```markdown
Result<User, LoginError>
├── .success(User)
└── .failure(LoginError)
```

성공하면:

```swift
.success(User(name: "Dani"))
```

실패하면:

```swift
.failure(.invalidPassword)
```

를 하나의 값으로 가진다.

## `.failure` is a Vlue

```swift
return .failure(.invalidPassword)
```

는 `throw` 가 아니다.

정상적인 `return` 을 통해 `Result` 의 `.failure` case 를 반환하는 것이다.

따라서:

```swift
let result = login(password: "wrong")

print("A")
```

에서 `.failure` 가 반환되어도 print("A") 까지 정상적인 실행 흐름이 이어진다.

## throws vs Result

### throws

```swift
func login(password: String) throws -> User
```

오류가 발생하면:

```swift
throw LoginError.invalidPassword
```

현재 정상적인 control flow가 중단되고 오류가 호출자에게 전달된다.

```text
함수 실행
↓
throw
↓
정상 실행 흐름 중단
↓
호출자에게 오류 전달
```

### Result

```swift
func login(password: String) -> Result<User, LoginError>
```

성공과 실패 모두 정상적인 반환값이다.

```text
함수 실행
↓
.success(User)
또는
.failure(LoginError)
↓
return
↓
호출자는 Result 값을 받음
↓
정상 실행 흐름 계속
```

## Store and Handle Later

Result 는 성공/실패 자체가 값이므로 변수에 저장하거나 다른 곳으로 전달할 수 있다.

```swift
var results: [Result<User, LoginError>] = []

results.append(login(password: "wrong"))
results.append(login(password: "swift"))
```

각 작업이 끝난 시점에 그 결과를 바로 처리할 필요가 없다.

나중에: 

```swift
for result in results {
    switch result {
        case .success(let user):
            print(user.name)
        
        case .failure(let error):
            print(error)
    }
}
```

처럼 처리할 수 있다.

즉 작업이 수행되는 시점과 결과를 처리하는 시점을 분리할 수 있다.

## Connection to Optional

이전에 학습한 Optional 과 구조적으로 비교할 수 있다.

```text
Optional<User>
├── .some(User)
└── .none

Result<User, LoginError>
├── .success(User)
└── .failure(LoginError)
```

`Optional` 은 값의 존재 여부를 표현한다.

Result 는 작업의 성공 여부와 성공 또는 실패에 대한 정보를 표현한다.

## Important Distinction

```text
throws
- 실패를 control flow로 표현
- throw 가 정상 실행 흐름에 즉시 영향을 줌

Result
- 성공/실패를 value 로 표현
- .failure 도 정상적인 반환값
- 저장하거나 전달할 수 있음
- 결과 처리를 나중으로 미룰 수 있음
```

## Takeaway

`Result` 를 단순히 "또 다른 에러 처리 문법" 으로 이해하지 않는다.

```swift
Result<User, LoginError>
```

를 보면:

> 이 값은 어떤 작업의 결과를 나타내며,
> 성공했다면 `User`,
> 실패했다면 `LoginError` 를 가지고 있다.

라고 읽는다.

한 줄로 정리하면: 

> `Result` 는 작업의 성공 또는 실패를 값으로 저장하여,
> 작업이 수행되는 시점과 그 결과를 처리하는 시점을 분리할 수 있게 한다.
