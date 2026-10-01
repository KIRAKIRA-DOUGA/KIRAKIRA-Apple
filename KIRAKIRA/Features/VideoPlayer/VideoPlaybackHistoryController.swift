import AVFoundation

@MainActor
final class VideoPlaybackHistoryController {
    private weak var player: AVPlayer?
    private var timeObserver: Any?
    private var videoID: Int?
    private var lastRecordedPosition: TimeInterval = 0
    private var recordTask: Task<Void, Never>?

    func attach(to player: AVPlayer, videoID: Int, resumeAt position: TimeInterval?) {
        stop()

        self.player = player
        self.videoID = videoID
        lastRecordedPosition = position ?? 0

        if let position, position > 0 {
            player.seek(
                to: CMTime(seconds: position, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.timeDidChange(time.seconds)
            }
        }
    }

    func flush() {
        guard let videoID,
            let position = player?.currentTime().seconds,
            position.isFinite,
            position >= 0,
            abs(position - lastRecordedPosition) >= 1
        else { return }

        lastRecordedPosition = position
        enqueueRecord(videoID: videoID, position: position)
    }

    func stop() {
        flush()
        if let player, let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        player = nil
        videoID = nil
    }

    private func timeDidChange(_ position: TimeInterval) {
        guard let videoID,
            position.isFinite,
            position >= 0,
            abs(position - lastRecordedPosition) >= 15
        else { return }

        lastRecordedPosition = position
        enqueueRecord(videoID: videoID, position: position)
    }

    private func enqueueRecord(videoID: Int, position: TimeInterval) {
        let previousTask = recordTask
        recordTask = Task {
            await previousTask?.value
            guard !Task.isCancelled else { return }
            await BrowsingHistoryManager.shared.record(videoID: videoID, position: position)
        }
    }
}
