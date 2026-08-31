import XCTest
@testable import HibiLens

final class CapturePerformanceLogTests: XCTestCase {
    func testPerformanceLoggingIsDisabledWithoutExplicitEnvironmentValue() {
        XCTAssertFalse(CapturePerformanceLog.isEnabled(environment: [:]))
        XCTAssertFalse(CapturePerformanceLog.isEnabled(environment: [
            "HIBILENS_PERFORMANCE_LOGGING": ""
        ]))
        XCTAssertFalse(CapturePerformanceLog.isEnabled(environment: [
            "HIBILENS_PERFORMANCE_LOGGING": "true"
        ]))
        XCTAssertFalse(CapturePerformanceLog.isEnabled(environment: [
            "HIBILENS_PERFORMANCE_LOGGING": "0"
        ]))
    }

    func testPerformanceLoggingAcceptsExactOptInEnvironmentValue() {
        XCTAssertTrue(CapturePerformanceLog.isEnabled(environment: [
            "HIBILENS_PERFORMANCE_LOGGING": "1"
        ]))
    }

    func testPerformanceLoggingSourceContainsReleaseCompilationBoundary() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = projectRoot
            .appendingPathComponent("HibiLens", isDirectory: true)
            .appendingPathComponent("Services", isDirectory: true)
            .appendingPathComponent("CapturePerformanceLog.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        XCTAssertGreaterThanOrEqual(source.components(separatedBy: "#if DEBUG").count - 1, 4)
    }
}
