# defer

## Question

```swift
func process(_ value: Int) {
    print("A")

    defer {
        print("B")
    }

    guard value > 0 else {
        print("C")
        return
    }

    print("D")
}

process(-1)
print("E")
```

`guard`에서 `return`되어 함수가 종료될 때 `defer`는 실행될까?

## My Prediction

```text
A
C
B
E
```

`defer` 선언까지 이미 실행이 도달했으므로, `guard` 에서 `return` 하더라도 함수가 종료되기 전에 `defer` 가 실행될 것이라고 생각했다.

## Principle

`defer` 는 선언 지점까지 실행이 도달했다면 현재 scope를 빠져나가기 직전에 실행된다.

반대로 `defer` 에 도달하기 전에 scope를 빠져나가면 등록되지 않는다.

```swift
guard value > 0 else {
    return
}

defer {
    print("B")
}
```

## Takeaway

`defer`를 볼 때는 다음 두 가지를 확인한다.

1. 실행 흐름이 `defer` 선언 지점까지 도달했는가?
2. 어느 scope를 빠져나갈 때 실행되는 `defer`인가?
