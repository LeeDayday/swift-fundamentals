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

