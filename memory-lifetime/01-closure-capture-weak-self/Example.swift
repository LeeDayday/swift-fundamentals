final class Downloader {
    var onComplete: (() -> Void)?

    init() {
        print("Downloader init")
    }

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

print("End")

// MARK: - Using weak self

final class WeakDownloader {
    var onComplete: (() -> Void)?

    func start() {
        onComplete = { [weak self] in
            self?.finish()
        }
    }

    private func finish() {
        print("Download finished")
    }

    deinit {
        print("WeakDownloader deinit")
    }
}

var weakDownloader: WeakDownloader? = WeakDownloader()
weakDownloader?.start()

weakDownloader = nil

// MARK: - Breaking the cycle manually

var anotherDownloader: Downloader? = Downloader()
anotherDownloader?.start()

anotherDownloader?.onComplete = nil
anotherDownloader = nil
