import Foundation

final class Worker {
    let name: String
    var task: Task<Void, Never>?

    init(name: String) {
        self.name = name
        print("init: \(name)")
    }

    // Case 1: Strong capture
    func startStrong() {
        task = Task {
            print("start: \(name)")
            try? await Task.sleep(for: .seconds(2))
            print("finish: \(name)")
        }
    }

    // Case 2: Weak capture + strong binding
    func startWeakWithBinding() {
        task = Task { [weak self] in
            guard let self else { return }

            print("start: \(name)")
            try? await Task.sleep(for: .seconds(2))
            print("finish: \(name)")
        }
    }

    // Case 3: Weak capture + value extraction
    func startWeakWithValue() {
        task = Task { [weak self] in 
            guard let name = self?.name else { return }

            print("start: \(name)")
            try? await Task.sleep(for: .seconds(2))
            print("finish: \(name)")
        }
    }

    deinit {
        print("deinit: \(name)")
        task?.cancel()
    }
}

func runStrong() {
    let worker = Worker(name: "Strong")
    worker.startStrong()
    print("runStrong finished")
}

func runWeakWithBinding() {
    let worker = Worker(name: "WeakBinding")
    worker.startWeakWithBinding()
    print("runweakWithBinding finished")
}

func runWeakWithValue() {
    let worker = Worker(name: "WeakValue")
    worker.startWeakWithValue()
    print("runWeakWithValue finished")
}

runStrong()
runWeakWithBinding()
runWeakWithValue()

// Keep the process alive long enough to observe
// the asynchronous tasks in this command-line example.
Thread.sleep(forTimeInterval: 3)
