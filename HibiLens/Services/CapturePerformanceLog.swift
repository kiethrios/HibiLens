import Foundation

enum CapturePerformanceLog {
#if DEBUG
    private static let environmentKey = "HIBILENS_PERFORMANCE_LOGGING"

    private static let enabled: Bool = {
        isEnabled(environment: ProcessInfo.processInfo.environment)
    }()
#endif

    static func isEnabled(environment: [String: String]) -> Bool {
#if DEBUG
        environment[environmentKey] == "1"
#else
        false
#endif
    }

    static func mark(_ name: String) {
#if DEBUG
        guard enabled else { return }
        print("[Performance] \(name)")
#endif
    }

    static func measure<T>(_ name: String, operation: () throws -> T) rethrows -> T {
#if DEBUG
        if enabled {
            let start = CFAbsoluteTimeGetCurrent()
            let result = try operation()
            log(name, startedAt: start)
            return result
        }
#endif
        return try operation()
    }

    static func measureAsync<T>(
        _ name: String,
        operation: () async throws -> T
    ) async rethrows -> T {
#if DEBUG
        if enabled {
            let start = CFAbsoluteTimeGetCurrent()
            let result = try await operation()
            log(name, startedAt: start)
            return result
        }
#endif
        return try await operation()
    }

#if DEBUG
    private static func log(_ name: String, startedAt start: CFAbsoluteTime) {
        let elapsedMilliseconds = (CFAbsoluteTimeGetCurrent() - start) * 1_000
        print("[Performance] \(name)=\(String(format: "%.2f", elapsedMilliseconds))ms")
    }
#endif
}
