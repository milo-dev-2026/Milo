import AVFoundation

/// 通话铃声播放器（对齐微信：主叫"嘟—嘟—"回铃音，被叫来电铃声）
/// 系统 AudioServices 提示音在静音/低音量下几乎听不到，这里用合成 WAV + AVAudioPlayer 循环播放
final class RingtonePlayer {

    static let shared = RingtonePlayer()

    private enum Style: Equatable {
        case ringback   // 主叫等待接听：450Hz 1s 响 + 2s 静音
        case incoming   // 被叫来电：800Hz 双短音 + 长间隔
    }

    private var player: AVAudioPlayer?
    private var currentStyle: Style?

    private init() {}

    /// 主叫回铃音
    func startRingback() {
        start(style: .ringback)
    }

    /// 被叫来电铃声
    func startIncoming() {
        start(style: .incoming)
    }

    func stop() {
        player?.stop()
        player = nil
        currentStyle = nil
    }

    private func start(style: Style) {
        guard currentStyle != style || player == nil else { return }
        stop()
        configureSession()
        guard let url = wavURL(for: style) else { return }
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        p.numberOfLoops = -1
        p.volume = 0.9
        p.prepareToPlay()
        p.play()
        player = p
        currentStyle = style
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // 回铃音/铃声走扬声器，且不打断当前已有音频（通话中 TRTC 会自行切换为 playAndRecord）
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    // MARK: - 合成 WAV

    private var cacheDirectory: URL? {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Ringtone", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func wavURL(for style: Style) -> URL? {
        guard let dir = cacheDirectory else { return nil }
        let url = dir.appendingPathComponent(style == .ringback ? "ringback.wav" : "incoming.wav")
        if FileManager.default.fileExists(atPath: url.path) { return url }

        var samples: [Int16] = []
        let rate = 44100.0
        func tone(freq: Double, seconds: Double, amplitude: Double = 0.6) {
            let count = Int(rate * seconds)
            for i in 0..<count {
                let t = Double(i) / rate
                let envelope = sin(min(1.0, min(t / 0.05, (seconds - t) / 0.05)) * Double.pi / 2)
                let value = sin(2 * Double.pi * freq * t) * amplitude * envelope
                samples.append(Int16(max(-32767, min(32767, value * 32767))))
            }
        }
        func silence(seconds: Double) {
            samples.append(contentsOf: Array(repeating: 0, count: Int(rate * seconds)))
        }

        switch style {
        case .ringback:
            tone(freq: 450, seconds: 1.0)
            silence(seconds: 2.0)
        case .incoming:
            tone(freq: 880, seconds: 0.25)
            silence(seconds: 0.15)
            tone(freq: 880, seconds: 0.25)
            silence(seconds: 1.6)
        }

        guard let data = wavData(from: samples, sampleRate: Int(rate)) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func wavData(from samples: [Int16], sampleRate: Int) -> Data? {
        let channels: UInt16 = 1
        let bits: UInt16 = 16
        let byteRate = UInt32(sampleRate) * UInt32(channels) * UInt32(bits / 8)
        let blockAlign = channels * (bits / 8)
        let dataSize = UInt32(samples.count * 2)

        var data = Data()
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // RIFF
        data.append(contentsOf: littleEndian(UInt32(36 + dataSize)))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // WAVE
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // fmt 
        data.append(contentsOf: littleEndian(UInt32(16)))
        data.append(contentsOf: littleEndian(UInt16(1)))   // PCM
        data.append(contentsOf: littleEndian(channels))
        data.append(contentsOf: littleEndian(UInt32(sampleRate)))
        data.append(contentsOf: littleEndian(byteRate))
        data.append(contentsOf: littleEndian(blockAlign))
        data.append(contentsOf: littleEndian(bits))
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // data
        data.append(contentsOf: littleEndian(dataSize))
        for s in samples {
            data.append(contentsOf: littleEndian(s))
        }
        return data
    }

    private func littleEndian<T>(_ value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.littleEndian) { Array($0) }
    }
}
