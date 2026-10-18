// MARK: - Ignoring Cancellation

func downloadIgnoringCancellation() async {
    print("download start")

    for step in 1...5 {
        try? await Task.sleep(for: .seconds(1))

        print("step \(step)")
    }

    print("download end")
}

let task = Task {
    await downloadIgnoringCancellation()
}

// MARK: - Handling Cancellation

func download() async {
    print("download start")

    for step in 1...5 {
        do {
            try await Task.sleep(for: .seconds(1))
        } catch {
            print("download cancelled")
            return
        }

        print("step \(step)")
    }

    print("download end")
}

let cancellableTask = Task {
    await download()
}

try? await Task.sleep(for: .seconds(2))

cancellableTask.cancel()
