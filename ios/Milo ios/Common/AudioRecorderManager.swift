import UIKit
import AVFoundation

class AudioRecorderManager: NSObject {

    static let shared = AudioRecorderManager()

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordTimer: Timer?
    private var recordDuration: CGFloat = 0

    var onRecordingChanged: ((CGFloat) -> Void)?
    var onRecordingFinished: ((Data, CGFloat) -> Void)?
    var onPlayFinished: (() -> Void)?

    private override init() {
        super.init()
    }

    func requestPermissionIfNeeded() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        if session.recordPermission == .granted {
            return true
        }
        return await withCheckedContinuation { continuation in
            session.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }

        let tempDir = NSTemporaryDirectory()
        let filePath = tempDir + "voice_\(Int(Date().timeIntervalSince1970)).m4a"
        let url = URL(fileURLWithPath: filePath)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            recordDuration = 0
            recordTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordDuration += 0.1
                self?.onRecordingChanged?(self?.recordDuration ?? 0)
            }
        } catch {
            return
        }
    }

    func stopRecording() {
        recorder?.stop()
        recordTimer?.invalidate()
        recordTimer = nil

        let url = recorder?.url
        recorder = nil

        let duration = recordDuration
        recordDuration = 0

        if duration < 1.0 {
            if let url = url {
                try? FileManager.default.removeItem(at: url)
            }
            return
        }

        if let url = url, let data = try? Data(contentsOf: url) {
            onRecordingFinished?(data, duration)
            try? FileManager.default.removeItem(at: url)
        }
    }

    func cancelRecording() {
        recorder?.stop()
        recordTimer?.invalidate()
        recordTimer = nil
        let url = recorder?.url
        recorder = nil
        recordDuration = 0
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func playAudio(data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.play()
        } catch {}
    }

    func playAudio(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
        } catch {}
    }

    func stopPlaying() {
        player?.stop()
        player = nil
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        onPlayFinished?()
    }
}
