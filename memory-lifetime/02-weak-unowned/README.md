# weak & unowned

## Question

`weak` 과 `unowned` 는 모두 strong reference cycle 을 피할 수 있는데, 왜 Swift에는 두 가지가 따로 존재할까?

```swift
final class Subscription {
    unowned let user: User

    init(user: User) {
        self.user = user
    }
}
```

`unowned` 는 `weak` 과 lifetime 관점에서 어떤 차이가 있을까?

## My Prediction

- 처음에는 `weak` 과 `unowned` 모두 reference count를 증가시키지 않으므로, 둘의 역할이 거의 비슷할 것이라고 생각했다.
- 또한 `unowned` 가 대상 객체가 해제되지 않도록 어느정도 보장해주는 기능일 수도 있겠다고 생각했다.

## What I Missed

`unowned` 는 대상 객체의 lifetime을 유지하지 않는다.

즉 다른 strong reference 가 모두 사라지면, `unowned` 로 참조되고 있더라도 객체는 해제될 수 있다.

```markdown
Subscription
    │
    │ unowned
    ↓
   User

User의 strong reference가 0
↓
User 해제
```

`unowned` 는 객체를 살려두는 기능이 아니다.

## Principle

### weak

```swift
weak var user: User?
```

- weak 은 대상 객체 객체의 lifetime을 유지하지 않는다.
- 대상이 먼저 해제될 수 있으며, 해제되면 참조는 자동으로 nil 이 된다.

```text
weak
-> RC 증가 X
-> 상대가 먼저 사라질 수 있음
-> 사라지면 nil
-> optional
```

따라서 weak 은 다음을 의미한다.

> 상대 객체가 없어지는 상황도 정상적인 상태로 존재할 수 있다.

### unowned

```swift
unowned let user: User
```

- `unowned` 역시 대상 객체의 lifetime 을 유지하지 않는다.
- 하지만 `weak` 처럼 대상이 사라졌을 때 안전하게 nil로 다루는 것을 전제로 하지 않는다.

```text
unowned
-> RC 증가 X
-> 상대가 먼저 사라지지 않을 것이라고 가정
-> optional 이 아님
-> 가정이 깨진 뒤 접근하면 runtime error
```

## Lifetime Relationship

### weak

```text
Owner
|────────|

Observer
     |──────────────|
```

참조 대상이 먼저 사라질 수 있다.

따라서:

```swift
weak var owenr: Owner?
```

처럼 absence를 optional로 표현해줘야 한다.

### unowned

```text
Owner
|────────────────────|

Child
     |──────────|
```

설계상 Child 가 살아있는 동안 Onwer 가 반드시 존재해야 한다고 가정한다.

```swift
unowned let owner: Owner
```

이 관계를 코드에 표현할 수 있다.

## Important Distinction

```markdown
weak
- 상대가 먼저 없어질 수도 있다
- absence를 허용
- nil 

unowned
- 상대를 내가 소유하지는 않지만, 내가 사용하는 동안에는 반드시 존재한다.
- absence를 허용하지 않는 lifetime 가정
```

둘 다 strong reference cycle을 피할 수 있지만, 차이는 메모리 누수 방지 자체보다 Lifetime 에 대한 설계 의도에 있다.

## Does unowned Guarantee Lifetime?

아니다.

```swift
unowned let user: User
```

는 다음을 보장하지 않는다.
> User가 실제로 Subscription 보다 오래 살아 있다.

unowned 는 그 lifetime 관계를 Swift 가 만들어주거나 유지해주는 기능이 아니다.

개발자가 이미 다음 관계를 보장한다고 가정하고 그 의도를 코드에 표현하는 것이다.

> Subscription 이 User를 사용하는 동안에는 User가 반드시 살아있다.

따라서 실제 코드가 이 가정을 지키는지도 별도로 확인해야 한다.

## Takeaway

weak 과 unowned 를 볼 때 단순히 "둘 다 RC를 증가시키지 않는다"에서 끝내지 않는다.

다음 질문을 한다.

1. 상대 객체가 먼저 사라지는 상황이 정상적으로 가능한가?
2. 가능하다면 nil 상태를 처리해야 하는가?
3. 상대가 반드시 더 오래 살아야 한다는 lifetime invariant 가 존재하는가?
4. 코드가 실제로 그 lifetime 관계를 보장하고 있는가?

한 줄로 정리하면:
> weak 은 absence를 허용하는 참조
> unowned 는 absence를 허용하지 않지만 소유하지도 않는 참조다.