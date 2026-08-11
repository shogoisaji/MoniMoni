import Foundation
import Testing
@testable import MoniMoni

@MainActor
struct SystemMonitorTests {
    private func makeIsolatedDefaults() -> (UserDefaults, String) {
        let suiteName = "MoniMoniTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func waitForRefresh(of monitor: SystemMonitor, after date: Date) async -> Bool {
        for _ in 0..<100 {
            if monitor.metrics.updatedAt > date {
                return true
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return false
    }

    @Test func defaultSelectedMetricIsCPUTemperature() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let monitor = SystemMonitor(userDefaults: defaults)
        #expect(monitor.selectedMetric == .cpuTemperature)
        #expect(monitor.refreshInterval == 2.0)
    }

    @Test func restoresSavedMetricAndInterval() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(MetricType.memoryUsage.rawValue, forKey: SystemMonitor.selectedMetricKey)
        defaults.set(5.0, forKey: SystemMonitor.refreshIntervalKey)

        let monitor = SystemMonitor(userDefaults: defaults)
        #expect(monitor.selectedMetric == .memoryUsage)
        #expect(monitor.refreshInterval == 5.0)
    }

    @Test func ignoresInvalidSavedMetric() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("not-a-metric", forKey: SystemMonitor.selectedMetricKey)

        let monitor = SystemMonitor(userDefaults: defaults)
        #expect(monitor.selectedMetric == .cpuTemperature)
    }

    @Test func ignoresNonPositiveRefreshInterval() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(0.0, forKey: SystemMonitor.refreshIntervalKey)

        let monitor = SystemMonitor(userDefaults: defaults)
        #expect(monitor.refreshInterval == 2.0)
    }

    @Test func persistsSelectedMetric() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let monitor = SystemMonitor(userDefaults: defaults)
        monitor.selectedMetric = .gpuUsage

        #expect(defaults.string(forKey: SystemMonitor.selectedMetricKey) == MetricType.gpuUsage.rawValue)
    }

    @Test func persistsRefreshInterval() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let monitor = SystemMonitor(userDefaults: defaults)
        monitor.refreshInterval = 10.0

        #expect(defaults.double(forKey: SystemMonitor.refreshIntervalKey) == 10.0)
        #expect(monitor.refreshInterval == 10.0)
    }

    @Test func refreshUpdatesTimestamp() async {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let monitor = SystemMonitor(userDefaults: defaults)
        let before = monitor.metrics.updatedAt

        monitor.refresh()

        #expect(await waitForRefresh(of: monitor, after: before))
    }

    @Test func menuBarTitleMatchesSelectedMetricFormatting() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let monitor = SystemMonitor(userDefaults: defaults)
        monitor.selectedMetric = .cpuUsage

        let expected = monitor.metrics.menuBarText(for: .cpuUsage)
        #expect(monitor.menuBarTitle == expected)
    }

    @Test func refreshMayPopulateMemoryMetrics() async {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let monitor = SystemMonitor(userDefaults: defaults)
        let before = monitor.metrics.updatedAt
        monitor.refresh()
        #expect(await waitForRefresh(of: monitor, after: before))

        // メモリは通常取得できる。他センサーは環境依存。
        if let memory = monitor.metrics.memoryUsage {
            #expect(memory >= 0 && memory <= 100)
        }
    }
}

