# Swift Fundamentals

다양한 Swift 코드를 관찰하고 동작을 추론하며, 그 과정에서 Swift의 핵심 원리를 학습하고 기록하는 저장소입니다. 

## Learning Areas

- Type System
- Memory & Lifetime
- Concurrency
- State & Mutation
- Error & Control Flow

## Learning Log

# Swift Fundamentals

다양한 Swift 코드를 관찰하고 동작을 추론하며, 그 과정에서 Swift의 핵심 원리를 학습하고 기록하는 저장소입니다.

## Learning Log

### Type System

* [Static Type & Dynamic Type](./type-system/01-static-dynamic-type)

  * Static type과 dynamic type이 함수 및 메서드 선택에 어떤 영향을 주는지 구분한다.

### Memory & Lifetime

* [Closure Capture & weak self](./memory-lifetime/01-closure-capture-weak-self)

  * Closure capture와 ARC의 관계를 이해하고, strong/weak reference가 객체의 lifetime에 미치는 영향을 판단한다.

### Concurrency

* [async/await & Suspension](./concurrency/01-async-await-suspension)

  * `async/await`의 역할과 suspension을 이해하고, Task와 Thread 및 비동기와 동시성을 구분한다.

* [async let](./concurrency/02-async-let)

  * 여러 비동기 작업을 먼저 시작하고 나중에 결과를 기다리는 흐름과 child task의 관계를 이해한다.

* [Task Cancellation](./concurrency/03-task-cancellation)

  * Task cancellation이 강제 종료가 아닌 취소 요청임을 이해하고, Task가 취소에 협력하여 종료되는 흐름을 이해한다.

### State & Mutation

* [Value Semantics & Mutation](./state-mutation/01-value-semantics-mutation)

  * Value type과 reference type의 상태 변경 차이를 이해하고, struct에서 `mutating`이 필요한 이유를 설명한다.

### Error & Control Flow

* [defer](./error-control-flow/01-defer)

  * `defer`가 등록되는 시점과 scope 종료 시 실행되는 시점을 구분한다.

* [throws & Error Propagation](./error-control-flow/02-throws-error-propagation)

  * `throw`, `throws`, `try`의 역할을 구분하고 오류가 호출자를 따라 전파되는 흐름을 이해한다.
