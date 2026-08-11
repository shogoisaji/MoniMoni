import Foundation
import Testing
@testable import MoniMoni

struct SystemMetricsTests {
    private var populated: SystemMetrics {
        var metrics = SystemMetrics()
        metrics.cpuTemperature = 56.4
        metrics.cpuUsage = 23.7
        metrics.gpuUsage = 41.2
        metrics.memoryUsage = 68.9
        metrics.updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        return metrics
    }

    @Test func emptyHasNilValues() {
        let empty = SystemMetrics.empty
        #expect(empty.cpuTemperature == nil)
        #expect(empty.cpuUsage == nil)
        #expect(empty.gpuUsage == nil)
        #expect(empty.memoryUsage == nil)
    }

    @Test func valueForTypeReturnsMatchingField() {
        let metrics = populated
        #expect(metrics.value(for: .cpuTemperature) == 56.4)
        #expect(metrics.value(for: .cpuUsage) == 23.7)
        #expect(metrics.value(for: .gpuUsage) == 41.2)
        #expect(metrics.value(for: .memoryUsage) == 68.9)
    }

    @Test func valueForTypeReturnsNilWhenMissing() {
        let metrics = SystemMetrics.empty
        for type in MetricType.allCases {
            #expect(metrics.value(for: type) == nil)
        }
    }

    @Test func menuBarTextFormatsTemperatureAndPercent() {
        let metrics = populated
        #expect(metrics.menuBarText(for: .cpuTemperature) == "56℃")
        #expect(metrics.menuBarText(for: .cpuUsage) == "24%")
        #expect(metrics.menuBarText(for: .gpuUsage) == "41%")
        #expect(metrics.menuBarText(for: .memoryUsage) == "69%")
    }

    @Test func menuBarTextUnavailableIsDash() {
        let metrics = SystemMetrics.empty
        for type in MetricType.allCases {
            #expect(metrics.menuBarText(for: type) == "—")
        }
    }

    @Test func detailTextFormatsWithOneDecimal() {
        let metrics = populated
        #expect(metrics.detailText(for: .cpuTemperature) == "56.4 ℃")
        #expect(metrics.detailText(for: .cpuUsage) == "23.7 %")
        #expect(metrics.detailText(for: .gpuUsage) == "41.2 %")
        #expect(metrics.detailText(for: .memoryUsage) == "68.9 %")
    }

    @Test func detailTextUnavailableMessage() {
        let metrics = SystemMetrics.empty
        for type in MetricType.allCases {
            #expect(metrics.detailText(for: type) == "Unavailable")
        }
    }

    @Test func equatableComparesFields() {
        var a = populated
        var b = populated
        #expect(a == b)

        b.cpuUsage = 99
        #expect(a != b)

        a.cpuUsage = 99
        #expect(a == b)
    }

    @Test func menuBarTextUsesPrintfStyleRounding() {
        var metrics = SystemMetrics()
        // String(format: "%.0f") は half-to-even 相当になることがある
        metrics.cpuUsage = 0.4
        #expect(metrics.menuBarText(for: .cpuUsage) == "0%")

        metrics.cpuUsage = 1.4
        #expect(metrics.menuBarText(for: .cpuUsage) == "1%")

        metrics.cpuUsage = 1.6
        #expect(metrics.menuBarText(for: .cpuUsage) == "2%")

        metrics.cpuUsage = 99.6
        #expect(metrics.menuBarText(for: .cpuUsage) == "100%")
    }
}
