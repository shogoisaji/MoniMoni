import Foundation
import Testing
@testable import MoniMoni

struct MetricTypeTests {
    @Test func allCasesHasFourMetrics() {
        #expect(MetricType.allCases.count == 4)
        #expect(MetricType.allCases == [
            .cpuTemperature,
            .cpuUsage,
            .gpuUsage,
            .memoryUsage
        ])
    }

    @Test(arguments: MetricType.allCases)
    func identifierMatchesRawValue(type: MetricType) {
        #expect(type.id == type.rawValue)
    }

    @Test func titlesAreNonEmptyAndUnique() {
        let titles = MetricType.allCases.map(\.title)
        #expect(titles.allSatisfy { !$0.isEmpty })
        #expect(Set(titles).count == titles.count)
    }

    @Test func shortTitlesAreNonEmpty() {
        for type in MetricType.allCases {
            #expect(!type.shortTitle.isEmpty)
        }
    }

    @Test func unitMatchesMetricKind() {
        #expect(MetricType.cpuTemperature.unit == "℃")
        #expect(MetricType.cpuUsage.unit == "%")
        #expect(MetricType.gpuUsage.unit == "%")
        #expect(MetricType.memoryUsage.unit == "%")
    }

    @Test(arguments: MetricType.allCases)
    func systemImageIsNonEmpty(type: MetricType) {
        #expect(!type.systemImage.isEmpty)
    }

    @Test func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in MetricType.allCases {
            let data = try encoder.encode(type)
            let decoded = try decoder.decode(MetricType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test func rawValueInit() {
        #expect(MetricType(rawValue: "cpuTemperature") == .cpuTemperature)
        #expect(MetricType(rawValue: "cpuUsage") == .cpuUsage)
        #expect(MetricType(rawValue: "gpuUsage") == .gpuUsage)
        #expect(MetricType(rawValue: "memoryUsage") == .memoryUsage)
        #expect(MetricType(rawValue: "unknown") == nil)
    }
}
