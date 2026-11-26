import Foundation

/// 尋找外部命令列工具（yt-dlp、ffmpeg）
enum ToolLocator {
    /// 包含 App 自動安裝工具的資料夾（~/Library/Application Support/TubeGrab/bin）
    static let searchDirs = [ToolInstaller.binDir.path, "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin",
                             NSHomeDirectory() + "/.local/bin", "/opt/local/bin"]

    static func find(_ name: String) -> String? {
        let fm = FileManager.default
        var dirs = searchDirs
        if let path = ProcessInfo.processInfo.environment["PATH"] {
            dirs += path.split(separator: ":").map(String.init)
        }
        for dir in dirs {
            let p = (dir as NSString).appendingPathComponent(name)
            if fm.isExecutableFile(atPath: p) { return p }
        }
        return nil
    }

    /// 從 Finder 開啟的 App 只有很精簡的 PATH，這裡補上 Homebrew 等常見路徑
    static var environment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        let extra = searchDirs.joined(separator: ":")
        env["PATH"] = extra + ":" + (env["PATH"] ?? "")
        env["PYTHONIOENCODING"] = "utf-8"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        return env
    }
}

struct ProcessResult {
    var status: Int32
    var stdout: String
    var stderr: String
}

struct ToolError: LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

/// 一個可取消、可逐行讀取輸出的子行程包裝
final class RunningProcess: @unchecked Sendable {
    let process = Process()
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }

    func cancel() {
        lock.lock(); cancelled = true; lock.unlock()
        if process.isRunning { process.terminate() }
    }
}

enum ProcessRunner {
    /// 執行並等待結束，回傳全部輸出
    static func run(_ executable: String, _ args: [String]) async throws -> ProcessResult {
        try await stream(executable, args, handle: RunningProcess(), onLine: { _, _ in })
    }

    /// 執行並逐行回呼輸出（isStderr 表示來源）
    static func stream(_ executable: String, _ args: [String], handle: RunningProcess,
                       onLine: @escaping @Sendable (String, Bool) -> Void) async throws -> ProcessResult {
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            throw ToolError(message: t("err.noYtdlp") + "\n(\(executable))")
        }
        return try await withCheckedThrowingContinuation { cont in
            let p = handle.process
            p.executableURL = URL(fileURLWithPath: executable)
            p.arguments = args
            p.environment = ToolLocator.environment
            let outPipe = Pipe(), errPipe = Pipe()
            p.standardOutput = outPipe
            p.standardError = errPipe
            p.standardInput = FileHandle.nullDevice

            let collector = OutputCollector(onLine: onLine)
            outPipe.fileHandleForReading.readabilityHandler = { h in
                let data = h.availableData
                if !data.isEmpty { collector.append(data, stderr: false) }
            }
            errPipe.fileHandleForReading.readabilityHandler = { h in
                let data = h.availableData
                if !data.isEmpty { collector.append(data, stderr: true) }
            }
            p.terminationHandler = { proc in
                outPipe.fileHandleForReading.readabilityHandler = nil
                errPipe.fileHandleForReading.readabilityHandler = nil
                // 讀完剩下的資料
                collector.append(outPipe.fileHandleForReading.readDataToEndOfFile(), stderr: false)
                collector.append(errPipe.fileHandleForReading.readDataToEndOfFile(), stderr: true)
                collector.flush()
                cont.resume(returning: ProcessResult(status: proc.terminationStatus,
                                                     stdout: collector.stdout, stderr: collector.stderr))
            }
            do { try p.run() } catch { cont.resume(throwing: error) }
        }
    }
}

/// 把子行程輸出切成一行一行（yt-dlp 的進度會用 \r 或 \n）
private final class OutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var outData = Data(), errData = Data()
    private var outBuf = "", errBuf = ""
    private let onLine: @Sendable (String, Bool) -> Void

    init(onLine: @escaping @Sendable (String, Bool) -> Void) { self.onLine = onLine }

    var stdout: String { lock.lock(); defer { lock.unlock() }; return String(decoding: outData, as: UTF8.self) }
    var stderr: String { lock.lock(); defer { lock.unlock() }; return String(decoding: errData, as: UTF8.self) }

    func append(_ data: Data, stderr isErr: Bool) {
        guard !data.isEmpty else { return }
        lock.lock()
        var lines: [String] = []
        if isErr { errData.append(data) } else { outData.append(data) }
        var buf = (isErr ? errBuf : outBuf) + String(decoding: data, as: UTF8.self)
        while let r = buf.rangeOfCharacter(from: CharacterSet(charactersIn: "\r\n")) {
            let line = String(buf[..<r.lowerBound])
            buf = String(buf[r.upperBound...])
            if !line.isEmpty { lines.append(line) }
        }
        if isErr { errBuf = buf } else { outBuf = buf }
        lock.unlock()
        for l in lines { onLine(l, isErr) }
    }

    func flush() {
        lock.lock()
        let o = outBuf, e = errBuf
        outBuf = ""; errBuf = ""
        lock.unlock()
        if !o.isEmpty { onLine(o, false) }
        if !e.isEmpty { onLine(e, true) }
    }
}
