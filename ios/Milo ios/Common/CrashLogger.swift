import UIKit

/// 崩溃日志捕获器 - 将崩溃信息写入Documents目录，便于调试
/// 文件位置：App Sandbox/Documents/crash_logs/
class CrashLogger {

    static let shared = CrashLogger()

    private var logFileURL: URL?

    private init() {
        setupLogFile()
        setupExceptionHandler()
        log("=== CrashLogger initialized ===")
        log("Device: \(UIDevice.current.model) iOS \(UIDevice.current.systemVersion)")
        log("App version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")")
    }

    private func setupLogFile() {
        let fm = FileManager.default
        if let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            let crashDir = docsDir.appendingPathComponent("crash_logs", isDirectory: true)
            try? fm.createDirectory(at: crashDir, withIntermediateDirectories: true)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "crash_\(dateFormatter.string(from: Date())).log"
            logFileURL = crashDir.appendingPathComponent(fileName)
            log("Log file: \(logFileURL?.lastPathComponent ?? "unknown")")
            log("Documents path: \(docsDir.path)")
        }
    }

    private func setupExceptionHandler() {
        // 捕获 Objective-C 异常
        NSSetUncaughtExceptionHandler { exception in
            CrashLogger.shared.handleException(exception)
        }

        // 捕获信号
        signal(SIGABRT) { sig in CrashLogger.shared.handleSignal(sig, name: "SIGABRT") }
        signal(SIGSEGV) { sig in CrashLogger.shared.handleSignal(sig, name: "SIGSEGV") }
        signal(SIGBUS) { sig in CrashLogger.shared.handleSignal(sig, name: "SIGBUS") }
        signal(SIGILL) { sig in CrashLogger.shared.handleSignal(sig, name: "SIGILL") }
        signal(SIGTRAP) { sig in CrashLogger.shared.handleSignal(sig, name: "SIGTRAP") }
    }

    private func handleException(_ exception: NSException) {
        log("=== CRASH: NSException ===")
        log("Name: \(exception.name.rawValue)")
        log("Reason: \(exception.reason ?? "unknown")")
        log("Call stack:")
        for (i, symbol) in exception.callStackSymbols.enumerated() {
            log("  \(i): \(symbol)")
        }
        log("=== End crash ===")
    }

    private func handleSignal(_ sig: Int32, name: String) {
        log("=== CRASH: Signal \(name) (\(sig)) ===")
        log("Call stack:")
        let symbols = Thread.callStackSymbols
        for (i, symbol) in symbols.enumerated() {
            log("  \(i): \(symbol)")
        }
        log("=== End crash ===")
    }

    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] \(message)\n"
        print(message)

        guard let url = logFileURL else { return }
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                if let handle = try? FileHandle(forWritingTo: url) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}
