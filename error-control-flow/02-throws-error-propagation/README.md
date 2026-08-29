# throws & Error Propagation

## Question

```swift
enum LoginError: Error {
    case invalidPassword
}

func validate(password: String) throws -> Bool {
    guard password == "swift" else {
        throw LoginError.invalidPassword
    }

    return true
}

func login() throws {
    print("A")

    try validate(password: "wrong")

    print("B")
}

try login()

print("C")
```

`validate()`에서 오류가 발생하면 실행 흐름은 어떻게 이어질까?

`try`는 오류를 처리하는 역할일까, 아니면 다른 의미일까?

## My Prediction

처음에는 다음과 같이 예상했다.

```text
A
C
```

`validate()`에서 오류가 발생하면 `login()`은 종료되고, 그 이후 `print("C")`는 실행될 수 있다고 생각했다.
하지만 `login()`도 오류를 처리하지 않고 바깥으로 전달하고 있었고, 최상위 호출에서도 오류를 처리하지 않았기 때문에 `C`까지 실행되지 않는다.

## Principle

### throw

```swift
throw LoginError.invalidPassword
```

현재의 정상 실행 흐름을 중단하고 오류를 던진다.

따라서 `throw` 이후의 코드는 실행되지 않는다.

```swift
throw LoginError.invalidPassword

return true // 실행되지 않음
```

### throws

```swift
func validate(password: String) throws -> Bool
```

해당 함수가 오류를 던질 수 있음을 선언한다.
`throws` 는 오류를 처리한다는 뜻이 아니다.
**함수 내부에서 오류를 처리하지 않으면 호출자에게 오류를 전달할 수 있다.**

### try
```swift
try validate(password: "wrong")
```
호출하는 함수가 오류를 던질 수 있다는 것을 나타낸다.

`try` 자체는 오류를 처리하지 않는다.

따라서 오류가 발생하면 현재 함수의 정상 실행 흐름도 중단될 수 있다.

### Error Propagation

현재 코드의 흐름은 다음과 같다.

```text
login()
↓
"A" 출력
↓
validate()
↓
throw LoginError.invalidPassword
↓
validate() 종료
↓
login()으로 오류 전달
↓
login()도 처리하지 않음
↓
호출자에게 다시 오류 전달
```

따라서:

```text
print("B")
print("C")
```

까지 정상 실행 흐름이 이어지지 않는다.

### Important Distinction

```text
throw
→ 오류를 발생시킨다.

throws
→ 이 함수가 오류를 전달할 수 있음을 선언한다.

try
→ 이 호출이 실패할 수 있음을 나타낸다.
→ 오류를 처리하지는 않는다.

do-catch
→ 전달된 오류를 받아서 처리한다.
```

## Takeaway

try를 보면 단순히 "에러 처리"라고 읽지 않는다.

다음 두 가지를 확인한다.

1. 이 호출에서 오류가 발생할 수 있는가?
2. 발생한 오류를 현재 scope에서 처리하는가, 아니면 바깥으로 전달하는가?
