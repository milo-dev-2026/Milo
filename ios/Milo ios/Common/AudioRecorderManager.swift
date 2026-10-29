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

    /// 播放远程语音消息：先下载到本地缓存再播放（AVAudioPlayer 不支持 http 远程 URL）
    /// onDownloadStart: 开始下载时回调（主线程），用于展示加载态
    func playRemoteAudio(_ remoteURL: URL, onDownloadStart: (() -> Void)? = nil) {
        let local = AudioRecorderManager.localCacheURL(for: remoteURL)
        if FileManager.default.fileExists(atPath: local.path) {
            playAudio(url: local)
            return
        }
        DispatchQueue.main.async { onDownloadStart?() }
        URLSession.shared.downloadTask(with: remoteURL) { [weak self] tmp, _, error in
            guard let self = self, let tmp = tmp, error == nil else { return }
            do {
                if FileManager.default.fileExists(atPath: local.path) {
                    try FileManager.default.removeItem(at: local)
                }
                try FileManager.default.moveItem(at: tmp, to: local)
                DispatchQueue.main.async {
                    self.playAudio(url: local)
                }
            } catch {}
        }.resume()
    }

    /// 远程语音的本地缓存路径（Caches/voice/<url散列>.<扩展名>，散列跨启动稳定）
    private static func localCacheURL(for remoteURL: URL) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voice", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        // FNV-1a 64bit 散列（Swift 自带 hashValue 跨启动不稳定，不可用）
        var hash: UInt64 = 1469598103934665603
        for byte in remoteURL.absoluteString.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        let ext = remoteURL.pathExtension.isEmpty ? "m4a" : remoteURL.pathExtension
        return cacheDir.appendingPathComponent(String(format: "%llx.%@", hash, ext))
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
