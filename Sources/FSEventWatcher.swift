import CoreServices
import Foundation

final class FSEventWatcher {
    private var stream: FSEventStreamRef?
    private var debounceWork: DispatchWorkItem?
    private let debounce: TimeInterval
    private let handler: () -> Void
    private let queue = DispatchQueue(label: "engineer.badry.devfs.fsevents")
    private let path: String

    init(path: String, debounce: TimeInterval, handler: @escaping () -> Void) {
        self.path = path
        self.debounce = debounce
        self.handler = handler
        start()
    }

    private func start() {
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<FSEventWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.schedule()
        }
        let paths = [path] as CFArray
        let flags = UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounce,
            flags
        )
        if let stream {
            FSEventStreamSetDispatchQueue(stream, queue)
            FSEventStreamStart(stream)
        }
    }

    private func schedule() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.handler()
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + debounce, execute: work)
    }

    func stop() {
        debounceWork?.cancel()
        debounceWork = nil
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
    }

    deinit {
        stop()
    }
}
