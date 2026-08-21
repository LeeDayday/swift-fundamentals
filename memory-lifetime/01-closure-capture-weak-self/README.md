# Closure Capture & weak self

## Question

```swift
final class Downloader {
    var onComplete: (() -> Void)?

    func start() {
        onComplete = {
            self.finish()
        }
    }

    private func finish() {
        print("Download finished")
    }

    deinit {
        print("Downloader deinit")
    }
}

var downloader: Downloader? = Downloader()
downloader?.start()

downloader = nil
```

`downloader` = nil이 되었는데도 `Downloader` 인스턴스가 바로 해제되지 않을 수 있는 이유는 무엇일까?

그리고 `[weak self]`는 이 관계를 어떻게 바꾸는가?

## My prediction

처음에는 `start()`가 실행되면 `onComplete` 내부의 `finish` 도 바로 실행된다고 생각했다.

하지만

```swift
onComplete = {
    self.finish()
}
```
는 클로저를 실행하는 것이 아니라,
`onComplete` 프로퍼티에 클로저를 저장하는 코드다.

클로저를 실행하려면 다음과 같은 호출이 필요하다.

```swift
onComplete?()
```

## What I missed

클로저는 자신의 외부에 있는 값을 capture 할 수 있다.

```swift
onComplete = {
    self.finish()
}
```
에서 클로저는 나중에도 `self.finish()`를 실행할 수 있어야 하므로 `self`에 대한 참조를 가지고 있어야 한다.

따라서 다음과 같은 관계가 만들어질 수 있다.

```text
Downloader
    ↓
onComplete
    ↓
Closure
    ↓
self
    ↓
Downloader
```

처음에는 클로저를 단순히 "나중에 실행할 코드"로만 생각했고,
클로저가 자신이 사용하는 객체의 lifetime에도 영향을 줄 수 있다는 점을 고려하지 못했다.

## Principle

### Closure Capture

클로저는 자신의 바깥에 있는 값을 capture하여 원래 scope의 실행이 끝난 뒤에도 사용할 수 있다.

```swift
func start() {
    onComplete = {
        self.finish()
    }
}
```

`start()` 가 종료된 이후에도 클로저가 실행될 수 있으므로, 클로저는 `self`를 기억해야 한다.

### ARC

ARC(Automatic Reference Counting)는 클래스 인스턴스에 대한 strong reference 를 추적하여 lifetime을 관리한다.

인스턴스를 유지하는 strong reference가 더 이상 존재하지 않으면, 인스턴스를 해제할 수 있고 `deinit`이 호출된다.

### Strong Reference Cycle

클로저가 self를 strong하게 capture하고, 동시에 self가 그 클로저를 프로퍼티로 저장하면 다음 구조가 만들어질 수 있다.

```text
Downloader
    ↓ (strong)
Closure
    ↓ (strong)
Downloader
```

외부의 

```swift
downloader = nil
```

이 실행되어도 내부의 strong reference 관계가 남아 있기 때문에 인스턴스가 해제되지 않을 수 있다.

### weak self

```swift
onComplete = { [weak self] in
    self?.finish()
}
```

[weak self] 는 클로저가 self를 weak reference로 capture하도록 한다. 

weak refernece는 객체의 lifetime을 유지하지 않는다.
따라서 외부의 strong reference가 모두 사라지면 `Downloader`는 클로저가 존재하더라도 해제될 수 있다.

객체가 이미 해제되었다면 `self`는 `nil`이 될 수 있으므로 
```swift
self?.finish()
```
처럼 optional로 접근한다.

## Important Distinction

```text
strong capture
-> 객체의 lifetime을 유지한다.

weak capture
-> 객체의 lifetime을 유지하지 않는다.
-> 객체가 먼저 해제되면 nil이 될 수 있다.
```

즉, `[weak self]`는 단순히 "메모리 누수를 막기 위해 항상 사용하는 문법"이 아니다.

클로저가 `self`의 lifetime을 유지해야 하는지를 판단해야 한다.

## Experiment

### 1. weak self 사용

```swift
onComplete = { [weak self] in
    self?.finish()
}
```

클로저가 `self`의 lifetime을 유지하지 않는다.

따라서 다른 strong reference가 없다면 Downloader는 해제될 수 있다.

### 2. Closure를 명시적으로 제거

```swift
onComplete = {
    self.finish()
}

onComplete = nil
```

strong capture를 사용하더라도 저장된 클로저를 적절한 시점에 제거하면 strong reference cycle을 끊을 수 있다.

## Design Takeaway

클로저 안에서 self를 사용한다고 해서 항상 [weak self]를 사용해야 하는 것은 아니다.

코드를 읽을 때 다음 관계를 먼저 확인한다.

1. 이 클로저는 어디에 저장되는가?
2. 누가 이 클로저를 소유하는가?
3. 클로저가 `self`를 strong하게 capture하면 서로 참조하는 구조가 되는가?
4. 클로저가 실행될 때까지 self가 반드시 살아있어야 하는가?

self가 사라졌다면 작업도 수행하지 않아도 되는 경우에는 weak capture가 적절할 수 있다.

반대로 작업이 수행되는 동안 self의 lifetime을 유지해야 한다면 strong capture가 의도에 더 맞을 수 있다.