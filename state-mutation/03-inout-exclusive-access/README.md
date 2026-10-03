# inout & Exclusive Access

## Question

```swift
struct Player {
    var score: Int
}

func addBomus(to player: inout Player) {
    player.score += 10
}

func reset(_ player: Player) {
    var copy = player
    copy.score = 0
}

var player = Player(score: 50)

addBonus(to: &player)
reset(player)
```

일반적인 parameter 와 `inout` parameter는 호출자의 값에 어떤 차이를 만들까?

그리고 `inout` 으로 값을 변경하는 동안 Swift는 왜 해당 값에 대한 접근을 제한할까?

## My Prediction

Player 는 struct 이므로 value type 이다.

따라서 일반 parameter로 전달하면 호출자가 가지고 있는 player 자체를 변경하지 않을 것으로 예상했다.

반면:

```swift
addBonus(to: &player)
```

에서는 `inout` 을 사용하므로 함수 내부의 변경이 호출자의 `player` 에도 반영될 것으로 예상했다.

## Principle

### Normal Parameter

```swift
func reset(_ player: Player)
```

`Player` 는 value type 이다.

함수 내부에서 parameter의 값을 변경하는 것은 호출자가 가진 `player` 를 직접 변경하는 의미가 아니다.


```swift
var copy = player
copy.score = 0
```
따라서 호출자의 값은 그대로 유지된다.

### inout Parameter

```swift
func addBonus(to player: inout Player) {
    player.score += 10
}

inout 은 함수가 호출자의 값을 변경하고 그 결과를 호출자에게 반영할 수 있도록 한다.

```text
값이 함수로 전달됨
        ↓
함수 내부에서 변경
        ↓
변경 결과가 호출자의 값에 반영
```

`in-out` 이라는 이름처럼 값이 함수 안으로 들어오고 변경된 결과가 다시 반영되는 것으로 이해할 수 있다.

### &

`inout` parameter를 호출할 때는 호출부에서도 `&` 을 사용한다.

```swift
addBonus(to: &player)
```

함수 선언:

```swift
func addBonus(to player: inout Player)
```

호출: 

```swift
addBonus(to: &player)
```

따라서 코드를 읽을 때 & 을 보면 해당 호출이 전달한 값을 변경할 수 있다는 점을 확인한다.

### inout & let

```swift
let player = Player(score: 50)
addBonus(to: &player)
```

는 불가능하다.

`let` 으로 선언된 value type 은 값을 변경할 수 없지만, `inout` 은 함수가 호출자의 값을 변경할 수 있어야 하기 때문이다.

따라서 `inout` 으로 전달되는 값은 변경 가능해야한다.

### Exclusive Access

Swift 는 값을 inout 으로 변경하는 동안 해당 값에 대한 충돌하는 접근을 제한한다.

예를 들어:

```swift

func compareAndUpdate(
    _ first: inout Player,
    _ second: inout Player
) {
    first.score += 10
    second.score += 20
}

var player = Player(score: 50)

compareAndUpdate(&player, &player)
```

처럼 같은 값을 두 개의 `inout` parameter로 전달하면 두 parameter 가 동시에 같은 값에 변경 접근하려는 구조가 된다.

Swift 는 `inout` 을 통한 변경 접근이 이루어지는 동안 해당 값에 대한 exclusive access 를 요구한다.

따라서 이러한 충돌하는 접근은 허용되지 않는다.

## Important Distinction

```text
일반 value type parameter
- 호출자의 값을 직접 변경하는 의미가 아님

inout parameter
- 호출자의 값을 변경할 수 있음
- 변경 결과가 호출자에게 반영됨

&
- 호출부에서 inout 전달임을 명시

Exclusive Access
- inout 으로 변경하는 동안 같은 값에 충돌하는 접근을 허용하지 않음
```

## inout vs Reference Type

inout 을 사용한다고 해서 struct 가 class 처럼 reference type 으로 변하는 것은 아니다.

```swift
addBonus(to: &player)
```

`Player` 는 여전히 value type 이다.

`inout` 은 value semantics 를 유지하면서 함수가 호출자의 값을 변경할 수 있도록 명시적인 mutation 통로를 제공하는 것으로 이해한다.

## Takeaway

`inout` 코드를 보면 다음을 확인한다.
1. 왜 이 함수가 호출자의 값을 변경해야 하는가?
2. 호출부에서 `&` 로 어떤 값을 전달하고 있는가?
3. 전달되는 값은 변경 가능한가?
4. 같은 값에 다른 변경 접근이 동시에 발생하지 않는가?

한 줄로 정리하면:

> `inout` 은 value type을 reference type으로 바꾸는 것이 아니라,
> 함수가 호출자의 값을 변경하고 그 결과를 반영할 수 있도록 명시하는 방법이다.
