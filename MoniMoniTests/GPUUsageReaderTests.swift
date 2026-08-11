import Testing
@testable import MoniMoni

struct GPUUsageReaderTests {
    @Test func readDoesNotCrashAndReturnsNilOrValidPercent() {
        let reader = GPUUsageReader()
        let usage = reader.read()

        // 機種・環境によって取得できないことがある
        if let usage {
            #expect(usage >= 0)
            #expect(usage <= 100)
        }
    }
}
